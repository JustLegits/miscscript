// ==UserScript==
// @name         Coursera AI Solver
// @namespace    https://github.com/
// @version      5.0.0
// @description  Giai quiz Coursera: Chain-of-Thought, multi-provider, text-matching chinh xac, video skip, auto-submit
// @match        https://www.coursera.org/*
// @grant        GM_addStyle
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        GM_xmlhttpRequest
// @grant        unsafeWindow
// @connect      api.groq.com
// @connect      generativelanguage.googleapis.com
// @run-at       document-start
// ==/UserScript==

(function () {
  'use strict';

  // ============================================================
  // SECTION 1 - TOKEN CAPTURE (runs at document-start)
  // Patch window.fetch & XHR to grab CSRF tokens + userID
  // Used later for video/reading completion
  // ============================================================
  const _state = {
    userId: null,
    courseId: null,
    authToken: null,
    headers: {},
    courseMaterials: null,
  };

  const TRACKED_HEADERS = new Set([
    'x-csrf2-cookie', 'x-csrf2-token', 'x-csrf3-token', 'x-csrftoken', 'x-requested-with',
  ]);

  function _captureHeaders(headers) {
    const pairs = Array.isArray(headers) ? headers : Object.entries(headers || {});
    pairs.forEach(function(pair) {
      var name = pair[0], value = pair[1];
      var n = String(name).toLowerCase();
      if (!TRACKED_HEADERS.has(n) || value == null) return;
      _state.headers[n] = String(value);
      if (n === 'x-csrf3-token') _state.authToken = String(value);
    });
  }

  function _processResponse(url, contentType, data, reqHeaders) {
    if (reqHeaders) _captureHeaders(reqHeaders);
    try {
      var id = data && data.context && data.context.dispatcher &&
               data.context.dispatcher.stores && data.context.dispatcher.stores.ApplicationStore &&
               data.context.dispatcher.stores.ApplicationStore.userData &&
               data.context.dispatcher.stores.ApplicationStore.userData.id;
      if (id) _state.userId = id;
    } catch(e) {}
    if (!_state.userId) {
      var m = String(url).match(/user\/([0-9]+)/) || String(url).match(/userId=([0-9]+)/);
      if (m) _state.userId = m[1];
    }
    if (String(url).includes('onDemandCourseMaterials.v2') &&
        data && data.linked && data.linked['onDemandCourseMaterialItems.v2']) {
      _state.courseMaterials = data;
    }
    if (String(url).includes('api/onDemandCourses.v1') || String(url).includes('slug=')) {
      try {
        var p = new URL(url).searchParams;
        if (p.has('slug')) _state.courseId = p.get('slug');
      } catch(e) {}
    }
  }

  // Patch fetch
  var _origFetch = unsafeWindow.fetch.bind(unsafeWindow);
  unsafeWindow.fetch = async function(resource, init) {
    var response = await _origFetch(resource, init);
    try {
      var clone = response.clone();
      var url = clone.url || (typeof resource === 'string' ? resource : (resource && resource.url) || '');
      var ct = clone.headers.get('content-type') || '';
      var reqH = [];
      try {
        var initHdrs = (init && init.headers) || (resource instanceof Request ? resource.headers : null);
        if (initHdrs) { new Headers(initHdrs).forEach(function(v,k){ reqH.push([k,v]); }); }
      } catch(e) {}
      if (ct.includes('application/json')) {
        clone.json().then(function(d){ _processResponse(url, ct, d, reqH); }).catch(function(){});
      } else {
        _processResponse(url, ct, null, reqH);
      }
    } catch(e) {}
    return response;
  };

  // Patch XHR
  var _origOpen = unsafeWindow.XMLHttpRequest.prototype.open;
  var _origSetHeader = unsafeWindow.XMLHttpRequest.prototype.setRequestHeader;
  var _origSend = unsafeWindow.XMLHttpRequest.prototype.send;

  unsafeWindow.XMLHttpRequest.prototype.open = function(method, url) {
    this._iUrl = url; this._iMethod = method; this._iHeaders = [];
    return _origOpen.apply(this, arguments);
  };
  unsafeWindow.XMLHttpRequest.prototype.setRequestHeader = function(name, value) {
    (this._iHeaders = this._iHeaders || []).push([String(name).toLowerCase(), String(value)]);
    return _origSetHeader.apply(this, arguments);
  };
  unsafeWindow.XMLHttpRequest.prototype.send = function(body) {
    this.addEventListener('load', function() {
      try {
        var url = this.responseURL || this._iUrl || '';
        var ct = this.getResponseHeader('content-type') || '';
        var data = null;
        if (ct.includes('application/json') && this.responseText) {
          try { data = JSON.parse(this.responseText); } catch(e) {}
        }
        _processResponse(url, ct, data, this._iHeaders || []);
      } catch(e) {}
    });
    return _origSend.apply(this, arguments);
  };

  // sleep helper
  var sleep = function(ms) { return new Promise(function(r){ setTimeout(r, ms); }); };

  // ============================================================
  // SECTION 2 - PROVIDERS CONFIG
  // Groq, Gemini, OpenAI, Claude, DeepSeek, OpenRouter
  // NOTE: Gemini uses ?key= query param (header blocked by browser)
  // NOTE: Groq reasoning_effort only works on deepseek-r1 models
  // ============================================================
  var PROVIDERS = {
    groq: {
  label: 'Groq',
  url: function() { return 'https://api.groq.com/openai/v1/chat/completions'; },
  defaultModel: 'openai/gpt-oss-120b',
  models: [
    { id: 'openai/gpt-oss-120b',           label: 'GPT-OSS 120B (Base Extension)' },
    { id: 'llama-3.3-70b-versatile',       label: 'Llama 3.3 70B (High Quality & Free)' },
    { id: 'deepseek-r1-distill-llama-70b', label: 'DeepSeek R1 70B (Reasoning)' },
    { id: 'openai/gpt-oss-20b',            label: 'GPT-OSS 20B (Base Extension)' },
    { id: 'llama-3.1-8b-instant',          label: 'Llama 3.1 8B (Fast)' },
  ],
  buildBody: function(model, systemMsg, userMsg) {
    var body = {
      model: model,
      temperature: 0.1,
      stream: false,
      max_tokens: 8192,                          // <-- Tránh bị cắt cụt token giữa chừng
      response_format: { type: "json_object" }, // <-- Ép Groq trả về JSON hợp lệ tuyệt đối
      messages: [
        { role: 'system', content: systemMsg },
        { role: 'user', content: userMsg }
      ]
    };
    if (model.indexOf('deepseek-r1') !== -1) body.reasoning_effort = 'default';
    return body;
  },
  buildHeaders: function(key) {
    return { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + key };
  },
  extractText: function(data) {
    return data && data.choices && data.choices[0] && data.choices[0].message && data.choices[0].message.content;
  },
},
    gemini: {
      label: 'Gemini',
      // Key passed as ?key= query param — more reliable than header in Tampermonkey
      url: function(model, key) {
        return 'https://generativelanguage.googleapis.com/v1beta/models/' + encodeURIComponent(model) + ':generateContent?key=' + encodeURIComponent(key);
      },
      defaultModel: 'gemini 3.7-flash',
      models: [
        { id: 'gemini-3.7-flash',      label: 'Gemini 3.7 Flash (Best)' },
        { id: 'gemini-3.8-flash',      label: 'Gemini 3.8 Flash (Good)' },
        { id: 'gemini-3.6-flash',        label: 'Gemini 3.6 Flash' },
        { id: 'gemini-3.5-flash',      label: 'Gemini 3.5 Flash' },
      ],
      buildBody: function(model, systemMsg, userMsg) {
        return {
          system_instruction: { parts: [{ text: systemMsg }] },
          contents: [{ role: 'user', parts: [{ text: userMsg }] }],
          generationConfig: { temperature: 0.1, responseMimeType: 'application/json' },
        };
      },
      // No auth header needed - key is in URL
      buildHeaders: function(key) {
        return { 'Content-Type': 'application/json' };
      },
      extractText: function(data) {
        if (!data || !data.candidates || !data.candidates[0]) return null;
        var parts = data.candidates[0].content && data.candidates[0].content.parts;
        return parts ? parts.map(function(p){ return p.text || ''; }).join('') : null;
      },
    },
  };

  // ============================================================
  // SECTION 3 - AI CALLER (via GM_xmlhttpRequest = no CORS)
  // ============================================================
    function buildSystemMessage() {
        return 'You are an expert academic assistant with deep subject-matter knowledge.\n\n' +
            'TASK: Solve every quiz question provided.\n\n' +
            'CHAIN-OF-THOUGHT PROCESS (mandatory for each question):\n' +
            '1. Identify the core academic concept being tested\n' +
            '2. Evaluate each option methodically\n' +
            '3. Eliminate wrong options with brief reasoning\n' +
            '4. Confirm the final answer\n\n' +
            'CRITICAL RULES:\n' +
            '- For single_answer/multiple_answer: copy option text EXACTLY as written (no paraphrasing)\n' +
            '- For text_input: concise accurate answer\n' +
            '- For essay: complete response matching question scope\n' +
            '- For code_expression: complete correct runnable code\n' +
            '- Do NOT use double quotes inside strings unless escaped (\\")\n' +
            '- Keep "thought" concise (under 25 words) to avoid token truncation\n\n' +
            'OUTPUT: Return ONLY a valid JSON object:\n' +
            '{"answers":[{"questionNumber":1,"thought":"brief reasoning","correctOptions":["Exact Option Text"]}]}';
    }

  function buildUserMessage(questions, context) {
    var msg = '';
    if (context) msg += '### Academic Context\n' + context + '\n\n';
    msg += 'Solve all questions below:\n\n';
    questions.forEach(function(q) {
      msg += 'Q' + q.questionNumber + ' (' + q.type + '): ' + q.question + '\n';
      if (q.options && q.options.length) {
        q.options.forEach(function(o, i) { msg += '  ' + (i+1) + '. ' + o.text + '\n'; });
      }
      if (q.type === 'code_expression') {
        msg += '  Language: ' + q.language + '\n  Current code:\n' + q.currentCode + '\n';
      }
      msg += '\n';
    });
    return msg;
  }

  function callAI(providerId, apiKey, model, systemMsg, userMsg) {
    var provider = PROVIDERS[providerId];
    if (!provider) return Promise.reject(new Error('Unknown provider: ' + providerId));
    var trimmedKey = apiKey.trim();
    // Pass key to url() — Gemini uses it as ?key= query param; others ignore it
    var url = provider.url(model, trimmedKey);
    var body = provider.buildBody(model, systemMsg, userMsg);
    var headers = provider.buildHeaders(trimmedKey);
    return new Promise(function(resolve, reject) {
      GM_xmlhttpRequest({
        method: 'POST', url: url, headers: headers, data: JSON.stringify(body),
        onload: function(res) {
          if (res.status === 200) {
            try {
              var data = JSON.parse(res.responseText);
              var text = provider.extractText(data);
              if (!text) return reject(new Error(provider.label + ' returned empty response.'));
              resolve(text);
            } catch(e) { reject(new Error('JSON parse error: ' + e.message)); }
          } else {
            var errMsg = provider.label + ' API Error [' + res.status + ']';
            try {
              var d = JSON.parse(res.responseText);
              var m = (d.error && d.error.message) || d.message;
              if (m) errMsg += ': ' + m;
            } catch(e) {}
            reject(new Error(errMsg));
          }
        },
        onerror: function() { reject(new Error('Network error reaching ' + provider.label)); },
      });
    });
  }

function parseAndValidateAnswers(rawText, questions) {
  var cleaned = rawText.replace(/^```(?:json)?\s*/i, '').replace(/\s*```\s*$/i, '').trim();
  if (!cleaned) throw new Error('AI returned empty response.');

  // Xóa trailing commas (lỗi thường gặp của các open-weight model)
  cleaned = cleaned.replace(/,\s*([\]}])/g, '$1');

  var parsed;
  try {
    parsed = JSON.parse(cleaned);
  } catch(e) {
    var match = cleaned.match(/\{[\s\S]*\}/);
    if (!match) throw new Error('AI did not return valid JSON.');
    try {
      var sanitized = match[0].replace(/,\s*([\]}])/g, '$1');
      parsed = JSON.parse(sanitized);
    } catch(err2) {
      throw new Error('JSON syntax error: ' + err2.message);
    }
  }

  var answers = Array.isArray(parsed) ? parsed
    : (Array.isArray(parsed && parsed.answers) ? parsed.answers : null);
  if (!answers) throw new Error('AI response missing "answers" array.');

  var questionMap = new Map(questions.map(function(q){ return [q.questionNumber, q]; }));
  var seen = new Set();
  var validated = answers.map(function(a) {
    if (!Number.isInteger(a && a.questionNumber) || !questionMap.has(a.questionNumber))
      throw new Error('AI referenced unknown question #' + (a && a.questionNumber));
    if (seen.has(a.questionNumber))
      throw new Error('Duplicate answer for Q' + a.questionNumber);
    seen.add(a.questionNumber);
    if (!Array.isArray(a.correctOptions) || !a.correctOptions.length)
      throw new Error('Q' + a.questionNumber + ' has no answer.');
    var q = questionMap.get(a.questionNumber);
    return {
      questionNumber: a.questionNumber,
      thought: a.thought || '',
      correctOptions: a.correctOptions.map(function(o) {
        return q.type === 'code_expression' ? o : String(o).trim();
      }),
    };
  });
  return validated.sort(function(a,b){ return a.questionNumber - b.questionNumber; });
}

  // ============================================================
  // SECTION 4 - QUESTION EXTRACTOR
  // Primary: extension selectors (data-testid based)
  // Fallback: script selectors (label/role based)
  // Options stored as TEXT (not index) - robust vs shuffling!
  // ============================================================
  function extractQuestions() {
    var questions = [], issues = [], seen = new Set();

    // Primary selectors from extension
    var blocks = Array.from(document.querySelectorAll('[data-testid^="part-Submission_"]'))
      .filter(function(el) {
        return el.querySelector('[id^="prompt-"] [data-testid="cml-viewer"]') && el.offsetParent !== null;
      });

    // Fallback from Tris script
    if (!blocks.length) {
      var selectors = [
        '[data-testid="part-Submission_MultipleChoiceQuestion"]',
        '[data-testid="part-Submission_CheckboxQuestion"]',
        '[data-testid="part-Submission_TextExactMatchQuestion"]',
        '[data-testid="part-Submission_TextReflectQuestion"]',
        '[data-testid="cds-quiz-question"]',
        '.rc-FormPartsQuestion', '.css-1erl2aq', '.css-12u8wr5',
      ];
      selectors.forEach(function(sel) {
        document.querySelectorAll(sel).forEach(function(el) {
          if (!seen.has(el) && el.offsetParent !== null) { seen.add(el); blocks.push(el); }
        });
      });
    }

    blocks.forEach(function(block, idx) {
      var qNum = idx + 1;
      var promptNode = block.querySelector('[id^="prompt-"] [data-testid="cml-viewer"]')
        || block.querySelector('[data-testid*="question-text"]')
        || block.querySelector('[class*="questionText"]')
        || block.querySelector('p');
      if (!promptNode) return;
      var questionText = promptNode.innerText.trim();
      if (questionText.length < 4) return;

      // Image context (from Tris script)
      var img = block.querySelector('img');
      if (img && img.alt && img.alt.trim()) questionText += '\n[Image: ' + img.alt.trim() + ']';

      var question = { questionNumber: qNum, type: 'unknown', question: questionText, options: [], _block: block };

      // Code (Monaco)
      if (block.dataset && block.dataset.testid === 'part-Submission_CodeExpressionQuestion') {
        var editorEl = block.querySelector('.monaco-editor[data-uri]');
        if (editorEl) {
          var modelUri = editorEl.getAttribute('data-uri') || '';
          var langEl = editorEl.closest('[data-mode-id]');
          var language = langEl ? langEl.getAttribute('data-mode-id') : 'unknown';
          if (modelUri.startsWith('inmemory://model/')) {
            try {
              var monaco = unsafeWindow.monaco;
              var monacoModel = monaco && monaco.editor && monaco.editor.getModels &&
                monaco.editor.getModels().find(function(m){ return m.uri && m.uri.toString() === modelUri; });
              if (monacoModel) {
                question.type = 'code_expression';
                question.language = language;
                question.currentCode = monacoModel.getValue();
                question._modelUri = modelUri;
                question._expectedValue = question.currentCode;
                questions.push(question);
              } else {
                issues.push({ questionNumber: qNum, error: 'Monaco not ready.' });
              }
            } catch(e) { issues.push({ questionNumber: qNum, error: e.message }); }
          }
        }
        return;
      }

      // Multiple choice - TEXT-BASED (key difference from Tris script!)
      var optionEls = Array.from(block.querySelectorAll('.rc-Option'));
      if (optionEls.length < 2) {
        optionEls = Array.from(block.querySelectorAll('label, [role="radio"], [role="checkbox"]'))
          .filter(function(el){ return el.innerText.trim().length > 0; });
      }
      if (optionEls.length >= 2) {
        var seenText = new Set();
        optionEls.forEach(function(el) {
          var textNode = el.querySelector('[data-testid="cml-viewer"]') || el;
          var txt = textNode.innerText.trim();
          if (!txt || seenText.has(txt)) return;
          seenText.add(txt);
          var inputEl = el.querySelector('input[type="radio"]') || el.querySelector('input[type="checkbox"]');
          question.options.push({ text: txt, el: inputEl || el });
          if (question.type === 'unknown') {
            question.type = (inputEl && inputEl.type === 'checkbox') ? 'multiple_answer' : 'single_answer';
          }
        });
      }
      if (question.options.length >= 2) { questions.push(question); return; }

      // Text / Essay
      var slateEditor = block.querySelector('[data-slate-editor="true"]');
      var textInput = block.querySelector('input[type="text"], textarea:not(.inputarea)');
      if (slateEditor)     { question.type = 'essay';      question._inputEl = slateEditor; }
      else if (textInput)  { question.type = 'text_input'; question._inputEl = textInput; }
      else return;
      questions.push(question);
    });

    return { questions: questions, issues: issues };
  }

  function getQuizContext() {
    var courseEl = document.querySelector('[data-testid="course-title"], .rc-BannerCourseTitle, .banner-title, a[href*="/learn/"]');
    var quizEl = document.querySelector('h1, [data-testid="quiz-title"], .quiz-title');
    var course = courseEl && courseEl.innerText && courseEl.innerText.trim();
    var quiz = quizEl && quizEl.innerText && quizEl.innerText.trim();
    var ctx = '';
    if (course) ctx += 'Course: "' + course + '"\n';
    if (quiz) ctx += 'Quiz: "' + quiz + '"\n';
    return ctx;
  }

  // ============================================================
  // SECTION 5 - ANSWER APPLIER
  // TEXT-BASED matching - not affected by Coursera option shuffling!
  // ============================================================
  async function applyAnswers(questions, answers, logFn) {
    var applied = 0, failures = [];
    for (var i = 0; i < questions.length; i++) {
      var q = questions[i];
      var answerData = answers.find(function(a){ return a.questionNumber === q.questionNumber; });
      if (!answerData || !answerData.correctOptions || !answerData.correctOptions.length) continue;
      if (q._block) {
        q._block.scrollIntoView({ behavior: 'smooth', block: 'center' });
        q._block.style.outline = '2px solid #00d4ff';
        q._block.style.borderRadius = '6px';
      }
      if (answerData.thought) logFn('Q' + q.questionNumber + ' CoT: ' + answerData.thought.slice(0, 80) + '...', 'info');

      // Code (Monaco)
      if (q.type === 'code_expression') {
        try {
          var monaco = unsafeWindow.monaco;
          var monacoModel = monaco && monaco.editor && monaco.editor.getModels &&
            monaco.editor.getModels().find(function(m){ return m.uri && m.uri.toString() === q._modelUri; });
          if (!monacoModel) throw new Error('Monaco model not found.');
          if (monacoModel.getValue() !== q._expectedValue) throw new Error('Code changed during AI call.');
          var code = String(answerData.correctOptions[0]).replace(/^```[\w]*\n?/, '').replace(/\n?```$/, '').trim();
          if (!code) throw new Error('AI returned empty code.');
          monacoModel.pushStackElement && monacoModel.pushStackElement();
          monacoModel.pushEditOperations([], [{ range: monacoModel.getFullModelRange(), text: code, forceMoveMarkers: true }], function(){ return null; });
          monacoModel.pushStackElement && monacoModel.pushStackElement();
          logFn('Q' + q.questionNumber + ' code applied!', 'ok'); applied++;
        } catch(e) {
          failures.push({ questionNumber: q.questionNumber, error: e.message });
          logFn('Q' + q.questionNumber + ' ERROR: ' + e.message, 'err');
        }
        if (q._block) q._block.style.outline = '';
        continue;
      }

      // Multiple choice - TEXT-BASED
      if (q.options && q.options.length) {
        var availableTexts = new Set(q.options.map(function(o){ return o.text; }));
        q.options.forEach(function(opt) {
          var shouldSelect = answerData.correctOptions.indexOf(opt.text) !== -1;
          var input = (opt.el && opt.el.tagName === 'INPUT') ? opt.el
            : (opt.el && opt.el.querySelector && opt.el.querySelector('input[type="radio"], input[type="checkbox"]'))
            || (opt.el && opt.el.closest && opt.el.closest('label') && opt.el.closest('label').querySelector('input'));
          if (input) {
            if (shouldSelect && !input.checked) input.click();
            else if (!shouldSelect && input.checked && input.type === 'checkbox') input.click();
          } else if (shouldSelect && opt.el && opt.el.click) { opt.el.click(); }
        });
        var allMatch = answerData.correctOptions.every(function(a){ return availableTexts.has(a); });
        if (allMatch) { logFn('Q' + q.questionNumber + ' => ' + answerData.correctOptions.join(' & '), 'ok'); applied++; }
        else { failures.push({ questionNumber: q.questionNumber, error: 'Option text mismatch' }); logFn('Q' + q.questionNumber + ' text mismatch - check manually', 'warn'); }
        if (q._block) q._block.style.outline = '';
        await sleep(120); continue;
      }

      // Text / Essay
      if (q._inputEl) {
        var value = String(answerData.correctOptions[0]);
        var el = q._inputEl;
        if (el.hasAttribute('contenteditable')) {
          el.focus(); await sleep(40);
          document.execCommand('selectAll', false, null);
          document.execCommand('insertText', false, value);
        } else {
          var proto = (el instanceof HTMLTextAreaElement) ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
          var setter = Object.getOwnPropertyDescriptor(proto, 'value');
          setter = setter && setter.set;
          if (setter) setter.call(el, value); else el.value = value;
          el.dispatchEvent(new Event('input', { bubbles: true }));
          el.dispatchEvent(new Event('change', { bubbles: true }));
        }
        logFn('Q' + q.questionNumber + ' text filled!', 'ok'); applied++;
      }
      if (q._block) q._block.style.outline = '';
      await sleep(120);
    }
    return { applied: applied, total: questions.length, failures: failures };
  }

  // ============================================================
  // SECTION 6 - VIDEO / READING COMPLETER
  // Uses captured auth tokens to call Coursera API directly
  // ============================================================
  function extractCompletableItems(data) {
    var SKIP = new Set(['quiz','exam','programming','phasedPeer','peer','ungradedAssignment','staffGraded','ungradedWidget']);
    var items = (data && data.linked && data.linked['onDemandCourseMaterialItems.v2']) || [];
    return items.filter(function(item) {
      var type = (item.contentSummary && item.contentSummary.typeName) || item.itemClass || 'unknown';
      var name = (item.name || '').toLowerCase();
      return item.id && !SKIP.has(type) && !name.includes('quiz') && !name.includes('exam');
    }).map(function(item) {
      return { id: item.id, type: (item.contentSummary && item.contentSummary.typeName) || item.itemClass || 'unknown' };
    });
  }

  async function startVideoCompletion(logFn) {
    var courseId = _state.courseId;
    if (!courseId) {
      var m = location.pathname.match(/\/learn\/([^\/]+)/);
      if (m) courseId = m[1];
    }
    if (!_state.authToken) throw new Error('Auth token missing - browse a video page first.');
    if (!courseId) throw new Error('Course ID missing - open the course page first.');
    logFn('Fetching course structure...', 'info');
    var apiUrl = 'https://www.coursera.org/api/onDemandCourseMaterials.v2/?q=slug&slug=' + courseId
      + '&includes=modules,lessons,items'
      + '&fields=moduleIds,onDemandCourseMaterialModules.v1(lessonIds,optional),'
      + 'onDemandCourseMaterialLessons.v1(elementIds,optional,itemIds),'
      + 'onDemandCourseMaterialItems.v2(name,isLocked,itemClass,contentSummary)';
    var res = await unsafeWindow.fetch(apiUrl, { headers: { 'X-CSRF3-Token': _state.authToken } });
    var data = await res.json();
    var internalId = courseId;
    if (data && data.elements && data.elements[0] && data.elements[0].id) internalId = data.elements[0].id;
    var items = extractCompletableItems(data);
    if (!items.length) throw new Error('No completable items found - are you on a course page?');
    logFn('Found ' + items.length + ' items. Completing...', 'ok');
    var CHUNK = 6, done = 0;
    for (var i = 0; i < items.length; i += CHUNK) {
      var chunk = items.slice(i, i + CHUNK);
      await Promise.all(chunk.map(async function(item) {
        var uid = _state.userId || '~';
        try {
          if (item.type === 'lecture' || item.type === 'unknown') {
            await unsafeWindow.fetch(
              'https://www.coursera.org/api/opencourse.v1/user/' + uid + '/course/' + courseId + '/item/' + item.id + '/lecture/videoEvents/ended?autoEnroll=false',
              { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF3-Token': _state.authToken }, body: JSON.stringify({ contentRequestBody: {} }) }
            );
          } else if (item.type === 'supplement' && internalId) {
            await unsafeWindow.fetch('https://www.coursera.org/api/onDemandSupplementCompletions.v1',
              { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF3-Token': _state.authToken },
                body: JSON.stringify({ userId: parseInt(uid) || uid, courseId: internalId, itemId: item.id }) }
            );
          }
          done++;
        } catch(e) {}
      }));
      logFn('Progress: ' + Math.min(i + CHUNK, items.length) + '/' + items.length, 'info');
      await sleep(400);
    }
    logFn('Done! ' + done + '/' + items.length + ' completed. Refresh the page!', 'ok');
  }

  // ============================================================
  // SECTION 7 - AUTO SUBMIT (from Tris script)
  // ============================================================
  async function autoSubmit(logFn) {
    logFn('Preparing submit...', 'info');
    var cb = document.getElementById('agreement-checkbox-base')
      || document.querySelector('input[type="checkbox"][id*="agreement"]')
      || document.querySelector('input[type="checkbox"][id*="honor"]');
    if (cb && !cb.checked) {
      cb.click(); cb.dispatchEvent(new Event('change', { bubbles: true }));
      logFn('Honor code checked!', 'ok');
    }
    await sleep(1800);
    var submitBtn = document.querySelector('[data-testid="submit-button"]')
      || Array.from(document.querySelectorAll('button')).find(function(b){ return /^submit$/i.test(b.innerText.trim()); });
    if (!submitBtn) { logFn('Submit button not found - submit manually.', 'warn'); return; }
    submitBtn.click(); logFn('Submit clicked!', 'ok');
    await sleep(2000);
    var confirmBtn = document.querySelector('[data-testid="dialog-submit-button"]')
      || Array.from(document.querySelectorAll('[role="dialog"] button')).find(function(b){ return /submit|confirm|ok/i.test(b.innerText); });
    if (confirmBtn) { confirmBtn.click(); logFn('Confirmed! Quiz submitted.', 'ok'); }
    else logFn('No confirm dialog - may already be submitted.', 'info');
  }

  // ============================================================
  // SECTION 8 - MAIN FLOW
  // ============================================================
  var _running = false;

  async function mainSolveFlow(logFn) {
    if (_running) { logFn('Already running - wait...', 'warn'); return; }
    var providerId = GM_getValue('cai_provider', 'groq');
    var apiKey = GM_getValue('cai_key_' + providerId, '');
    var model = GM_getValue('cai_model_' + providerId, PROVIDERS[providerId] && PROVIDERS[providerId].defaultModel);
    var autoSubmitEnabled = GM_getValue('cai_auto_submit', false);
    if (!apiKey || !apiKey.trim()) {
      logFn('No API key for ' + (PROVIDERS[providerId] && PROVIDERS[providerId].label) + '. Go to Settings tab.', 'warn'); return;
    }
    var extracted = extractQuestions();
    var questions = extracted.questions, issues = extracted.issues;
    if (!questions.length) { logFn('No questions found - are you on a quiz page?', 'warn'); return; }
    if (issues.length) issues.forEach(function(iss){ logFn('Q' + iss.questionNumber + ': ' + iss.error, 'warn'); });
    logFn('Found ' + questions.length + ' questions. Sending to ' + PROVIDERS[providerId].label + ' (CoT, temp 0.1' + (providerId === 'groq' ? ', reasoning_effort)...' : ')...'), 'info');
    _running = true;
    try {
      var context = getQuizContext();
      var systemMsg = buildSystemMessage();
      var userMsg = buildUserMessage(questions, context);
      var rawText = await callAI(providerId, apiKey, model, systemMsg, userMsg);
      var answers = parseAndValidateAnswers(rawText, questions);
      logFn('AI answered! Filling answers...', 'ok');
      var result = await applyAnswers(questions, answers, logFn);
      if (!result.failures.length) {
        logFn('All ' + result.applied + '/' + result.total + ' answers filled!', 'ok');
      } else {
        logFn('Applied ' + result.applied + '/' + result.total + '. Failures: Q' + result.failures.map(function(f){ return f.questionNumber; }).join(', Q'), 'warn');
      }
      if (autoSubmitEnabled && !result.failures.length) {
        await sleep(1200); await autoSubmit(logFn);
      }
    } catch(err) {
      logFn('Error: ' + err.message, 'err');
    } finally {
      _running = false;
    }
  }

  // ============================================================
  // SECTION 9 - UI (cyberpunk panel, 3 tabs)
  // ============================================================
  GM_addStyle([
    '@import url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap");',
    '#cai-root{position:fixed;bottom:24px;right:24px;width:380px;font-family:Inter,system-ui,sans-serif;font-size:13px;z-index:2147483647;border-radius:16px;overflow:hidden;box-shadow:0 0 0 1px #00d4ff30,0 20px 60px rgba(0,0,0,.7),0 0 40px #00d4ff15;background:#080c10;}',
    '#cai-root *{box-sizing:border-box;}',
    '#cai-header{background:linear-gradient(135deg,#0d1a24,#091218);padding:14px 16px;display:flex;align-items:center;justify-content:space-between;cursor:pointer;border-bottom:1px solid #00d4ff20;user-select:none;}',
    '.cai-logo{display:flex;align-items:center;gap:10px;}',
    '.cai-icon{width:28px;height:28px;border-radius:8px;background:linear-gradient(135deg,#00d4ff20,#7c3aed20);border:1px solid #00d4ff40;display:flex;align-items:center;justify-content:center;font-size:14px;}',
    '.cai-title{font-weight:600;font-size:14px;color:#e2e8f0;letter-spacing:.3px;}',
    '.cai-version{font-size:10px;color:#00d4ff;background:#00d4ff15;border:1px solid #00d4ff30;padding:2px 6px;border-radius:20px;font-family:JetBrains Mono,monospace;margin-left:6px;}',
    '.cai-toggle-btn{background:none;border:none;color:#64748b;cursor:pointer;font-size:16px;padding:0;line-height:1;transition:color .2s;}',
    '.cai-toggle-btn:hover{color:#00d4ff;}',
    '#cai-body{background:#080c10;}',
    '#cai-tabs{display:flex;border-bottom:1px solid #1a2535;background:#0a0f18;}',
    '.cai-tab{flex:1;padding:10px 8px;text-align:center;cursor:pointer;font-size:11px;font-weight:500;color:#4a5568;letter-spacing:.5px;text-transform:uppercase;transition:all .2s;border-bottom:2px solid transparent;user-select:none;}',
    '.cai-tab:hover{color:#94a3b8;}',
    '.cai-tab.active{color:#00d4ff;border-bottom-color:#00d4ff;background:#00d4ff08;}',
    '.cai-pane{display:none;padding:14px 16px;}',
    '.cai-pane.active{display:block;}',
    '#cai-log,#cai-log-skip{background:#050810;border:1px solid #1a2535;border-radius:8px;padding:10px;overflow-y:auto;margin-bottom:12px;font-family:JetBrains Mono,monospace;font-size:10.5px;line-height:1.7;scrollbar-width:thin;scrollbar-color:#1a2535 transparent;}',
    '#cai-log{height:130px;}#cai-log-skip{height:100px;}',
    '#cai-log::-webkit-scrollbar,#cai-log-skip::-webkit-scrollbar{width:4px;}',
    '#cai-log::-webkit-scrollbar-thumb,#cai-log-skip::-webkit-scrollbar-thumb{background:#1a2535;border-radius:2px;}',
    '.cle{color:#4a5568;}.cle.ok{color:#10b981;}.cle.warn{color:#f59e0b;}.cle.err{color:#ef4444;}.cle.info{color:#60a5fa;}',
    '.cai-btn{width:100%;padding:11px 16px;border-radius:8px;border:1px solid #1a2535;background:#0d1520;color:#94a3b8;font-family:Inter,sans-serif;font-size:12px;font-weight:500;cursor:pointer;transition:all .2s;margin-bottom:8px;display:flex;align-items:center;justify-content:center;gap:6px;}',
    '.cai-btn:hover{background:#121e2e;color:#e2e8f0;}.cai-btn:active{transform:scale(.98);}',
    '.cai-btn.primary{background:linear-gradient(135deg,#00d4ff15,#7c3aed10);border-color:#00d4ff40;color:#00d4ff;font-weight:600;}',
    '.cai-btn.primary:hover{background:linear-gradient(135deg,#00d4ff25,#7c3aed20);border-color:#00d4ff70;box-shadow:0 0 20px #00d4ff20;}',
    '.cai-btn.success{background:#10b98115;border-color:#10b98140;color:#10b981;}',
    '.cai-btn.danger{background:#ef444410;border-color:#ef444430;color:#ef4444;}',
    '.cai-btn-row{display:flex;gap:8px;margin-bottom:8px;}.cai-btn-row .cai-btn{margin-bottom:0;}',
    '.cai-toggle-row{display:flex;align-items:center;justify-content:space-between;padding:10px 14px;background:#0a0f18;border:1px solid #1a2535;border-radius:8px;margin-bottom:10px;}',
    '.cai-toggle-label{color:#94a3b8;font-size:12px;}',
    '.cai-switch{position:relative;width:36px;height:20px;}',
    '.cai-switch input{opacity:0;width:0;height:0;}',
    '.cai-slider{position:absolute;inset:0;background:#1a2535;border-radius:20px;transition:.2s;}',
    '.cai-slider:before{content:"";position:absolute;width:14px;height:14px;left:3px;bottom:3px;background:#4a5568;border-radius:50%;transition:.2s;}',
    '.cai-switch input:checked+.cai-slider{background:#00d4ff30;}',
    '.cai-switch input:checked+.cai-slider:before{transform:translateX(16px);background:#00d4ff;}',
    '.cai-label{display:block;font-size:11px;color:#64748b;margin-bottom:5px;text-transform:uppercase;letter-spacing:.5px;}',
    '.cai-sel,.cai-inp{width:100%;background:#0a0f18;border:1px solid #1a2535;border-radius:8px;color:#e2e8f0;padding:9px 12px;font-family:Inter,sans-serif;font-size:12px;margin-bottom:10px;outline:none;transition:border-color .2s;}',
    '.cai-sel:focus,.cai-inp:focus{border-color:#00d4ff50;}',
    '.cai-sel option{background:#0a0f18;}',
    '.cai-inp[type=password]{font-family:JetBrains Mono,monospace;letter-spacing:2px;}',
    '.cai-divider{height:1px;background:#1a2535;margin:10px 0;}',
    '.cai-info{color:#4a5568;font-size:11px;line-height:1.6;margin:0;}',
    '.cai-info a{color:#00d4ff;}',
  ].join(''));

  function buildPanel() {
    if (document.getElementById('cai-root')) return;
    if (!document.body) return;
    // Safety: if saved provider no longer exists (e.g. 'openai' was removed), fall back to 'groq'
    var provId = GM_getValue('cai_provider', 'groq');
    if (!PROVIDERS[provId]) { provId = 'groq'; GM_setValue('cai_provider', 'groq'); }
    var autoSub = GM_getValue('cai_auto_submit', false);
    var provOpts = Object.keys(PROVIDERS).map(function(id) {
      return '<option value="' + id + '">' + PROVIDERS[id].label + '</option>';
    }).join('');
    var currentProv = PROVIDERS[provId];
    var modelOpts = (currentProv && currentProv.models || []).map(function(m) {
      return '<option value="' + m.id + '">' + m.label + '</option>';
    }).join('');
    var panel = document.createElement('div');
    panel.id = 'cai-root';
    panel.innerHTML = '<div id="cai-header">'
      + '<div class="cai-logo"><div class="cai-icon">&#9889;</div><div>'
      + '<span class="cai-title">AI Solver Pro</span><span class="cai-version">v5.0</span></div></div>'
      + '<button class="cai-toggle-btn" id="cai-collapse-btn">&#9660;</button></div>'
      + '<div id="cai-body">'
        + '<div id="cai-tabs">'
          + '<div class="cai-tab active" data-tab="solve">&#9889; Solve</div>'
          + '<div class="cai-tab" data-tab="skip">&#9197; Skip</div>'
          + '<div class="cai-tab" data-tab="settings">&#9881; Settings</div>'
        + '</div>'
        + '<div class="cai-pane active" id="cai-pane-solve">'
          + '<div id="cai-log"></div>'
          + '<div class="cai-toggle-row"><span class="cai-toggle-label">&#128640; Auto-Submit after solve</span>'
            + '<label class="cai-switch"><input type="checkbox" id="cai-autosub-toggle"' + (autoSub ? ' checked' : '') + '>'
            + '<span class="cai-slider"></span></label></div>'
          + '<button class="cai-btn primary" id="cai-solve-btn">&#9889; Auto Solve with CoT</button>'
          + '<div class="cai-btn-row">'
            + '<button class="cai-btn success" id="cai-submit-btn">&#10003; Submit Only</button>'
            + '<button class="cai-btn danger" id="cai-clear-btn">&#128465; Clear Log</button>'
          + '</div></div>'
        + '<div class="cai-pane" id="cai-pane-skip">'
          + '<div id="cai-log-skip"></div>'
          + '<button class="cai-btn primary" id="cai-skip-btn">&#9197; Skip Videos &amp; Readings</button>'
          + '<p class="cai-info" style="margin-top:8px;">Browse a video first to capture auth tokens, then click Skip.</p>'
        + '</div>'
        + '<div class="cai-pane" id="cai-pane-settings">'
          + '<label class="cai-label">AI Provider</label>'
          + '<select class="cai-sel" id="cai-provider-sel">' + provOpts + '</select>'
          + '<label class="cai-label">Model</label>'
          + '<select class="cai-sel" id="cai-model-sel">' + modelOpts + '</select>'
          + '<label class="cai-label">API Key</label>'
          + '<input type="password" class="cai-inp" id="cai-key-inp" placeholder="Paste API key here..." value="' + GM_getValue('cai_key_' + provId, '') + '">'
          + '<div class="cai-btn-row">'
            + '<button class="cai-btn success" id="cai-save-btn">&#128190; Save</button>'
            + '<button class="cai-btn" id="cai-verify-btn">&#128268; Verify</button>'
          + '</div>'
          + '<div class="cai-divider"></div>'
          + '<p class="cai-info">Get free keys: <a href="https://console.groq.com/keys" target="_blank">Groq</a> &middot; <a href="https://aistudio.google.com/api-keys" target="_blank">Gemini</a></p>'
        + '</div>'
      + '</div>';
    document.body.appendChild(panel);
    wireEvents(panel);
  }

  function wireEvents(panel) {
    var collapsed = GM_getValue('cai_collapsed', false);
    var body = panel.querySelector('#cai-body');
    var colBtn = panel.querySelector('#cai-collapse-btn');
    body.style.display = collapsed ? 'none' : 'block';
    colBtn.innerHTML = collapsed ? '&#9658;' : '&#9660;';
    panel.querySelector('#cai-header').addEventListener('click', function(e) {
      if (e.target === colBtn || (colBtn && colBtn.contains(e.target))) {
        collapsed = !collapsed;
        body.style.display = collapsed ? 'none' : 'block';
        colBtn.innerHTML = collapsed ? '&#9658;' : '&#9660;';
        GM_setValue('cai_collapsed', collapsed);
      }
    });
    // Tabs
    panel.querySelectorAll('.cai-tab').forEach(function(tab) {
      tab.addEventListener('click', function() {
        panel.querySelectorAll('.cai-tab').forEach(function(t){ t.classList.remove('active'); });
        panel.querySelectorAll('.cai-pane').forEach(function(p){ p.classList.remove('active'); });
        tab.classList.add('active');
        var pane = panel.querySelector('#cai-pane-' + tab.dataset.tab);
        if (pane) pane.classList.add('active');
      });
    });
    // Log helpers
    function log(msg, type) {
      var el = document.getElementById('cai-log');
      if (!el) return;
      var line = document.createElement('div');
      line.className = 'cle ' + (type || '');
      line.textContent = '[' + new Date().toLocaleTimeString() + '] ' + msg;
      el.appendChild(line); el.scrollTop = el.scrollHeight;
    }
    function logSkip(msg, type) {
      var el = document.getElementById('cai-log-skip');
      if (!el) return;
      var line = document.createElement('div');
      line.className = 'cle ' + (type || '');
      line.textContent = '[' + new Date().toLocaleTimeString() + '] ' + msg;
      el.appendChild(line); el.scrollTop = el.scrollHeight;
    }
    // Solve
    panel.querySelector('#cai-solve-btn').addEventListener('click', function(){ mainSolveFlow(log); });
    // Submit only
    panel.querySelector('#cai-submit-btn').addEventListener('click', function(){ autoSubmit(log); });
    // Clear
    panel.querySelector('#cai-clear-btn').addEventListener('click', function(){ document.getElementById('cai-log').innerHTML = ''; });
    // Auto-submit toggle
    panel.querySelector('#cai-autosub-toggle').addEventListener('change', function(e) {
      GM_setValue('cai_auto_submit', e.target.checked);
      log('Auto-Submit: ' + (e.target.checked ? 'ON' : 'OFF'), 'info');
    });
    // Skip videos
    panel.querySelector('#cai-skip-btn').addEventListener('click', function() {
      startVideoCompletion(logSkip).catch(function(e){ logSkip(e.message, 'err'); });
    });
    // Settings
    var provSel = panel.querySelector('#cai-provider-sel');
    var modelSel = panel.querySelector('#cai-model-sel');
    var keyInp = panel.querySelector('#cai-key-inp');
    provSel.value = GM_getValue('cai_provider', 'groq');
    modelSel.value = GM_getValue('cai_model_' + provSel.value, PROVIDERS[provSel.value] && PROVIDERS[provSel.value].defaultModel);
    provSel.addEventListener('change', function() {
      var pid = provSel.value;
      var prov = PROVIDERS[pid];
      modelSel.innerHTML = (prov && prov.models || []).map(function(m){
        return '<option value="' + m.id + '">' + m.label + '</option>';
      }).join('');
      modelSel.value = GM_getValue('cai_model_' + pid, prov && prov.defaultModel);
      keyInp.value = GM_getValue('cai_key_' + pid, '');
    });
    panel.querySelector('#cai-save-btn').addEventListener('click', function() {
      var pid = provSel.value;
      GM_setValue('cai_provider', pid);
      GM_setValue('cai_model_' + pid, modelSel.value);
      GM_setValue('cai_key_' + pid, keyInp.value.trim());
      log('Saved: ' + (PROVIDERS[pid] && PROVIDERS[pid].label) + ' / ' + modelSel.value, 'ok');
    });
    panel.querySelector('#cai-verify-btn').addEventListener('click', async function() {
      var pid = provSel.value;
      var key = keyInp.value.trim();
      if (!key) { log('No API key entered.', 'warn'); return; }
      log('Verifying ' + (PROVIDERS[pid] && PROVIDERS[pid].label) + '...', 'info');
      try {
        var prov = PROVIDERS[pid];
        var testBody = prov.buildBody(modelSel.value, 'You are a test.', 'Reply with valid JSON: {"status":"OK"}');
        await new Promise(function(resolve, reject) {
          GM_xmlhttpRequest({
            method: 'POST',
            url: prov.url(modelSel.value, key),
            headers: prov.buildHeaders(key),
            data: JSON.stringify(testBody),
            onload: function(res) {
              if (res.status === 200) {
                resolve();
              } else {
                var errDetail = 'HTTP ' + res.status;
                try {
                  var d = JSON.parse(res.responseText);
                  var m = (d.error && d.error.message) || d.message;
                  if (m) errDetail += ': ' + m;
                } catch(e) {}
                reject(new Error(errDetail));
              }
            },
            onerror: function() { reject(new Error('Network error')); },
          });
        });
        log((PROVIDERS[pid] && PROVIDERS[pid].label) + ' connected!', 'ok');
      } catch(e) { log('Failed: ' + e.message, 'err'); }
    });
  }

  // Inject panel after DOM ready with SPA recovery
  function tryInject() {
    if (document.getElementById('cai-root')) return;
    if (document.body) {
      buildPanel();
    } else {
      setTimeout(tryInject, 200);
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function(){ setTimeout(tryInject, 400); });
  } else {
    setTimeout(tryInject, 400);
  }

  setInterval(function() {
    if (!document.getElementById('cai-root') && document.body) {
      tryInject();
    }
  }, 1500);

})();
