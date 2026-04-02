import{l as le,x as ue}from"./BEsPXkwB.js";import{c as fe,f as N,A as p}from"./DpmIfLEg.js";import{w as he,g as F}from"./Bip_i8UA.js";function ze(e,t,n){var i=ue(e,t);i&&i.set&&(e[t]=n,le(()=>{e[t]=null}))}var P;(function(e){e.STRING="string",e.NUMBER="number",e.INTEGER="integer",e.BOOLEAN="boolean",e.ARRAY="array",e.OBJECT="object"})(P||(P={}));/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */var j;(function(e){e.LANGUAGE_UNSPECIFIED="language_unspecified",e.PYTHON="python"})(j||(j={}));var H;(function(e){e.OUTCOME_UNSPECIFIED="outcome_unspecified",e.OUTCOME_OK="outcome_ok",e.OUTCOME_FAILED="outcome_failed",e.OUTCOME_DEADLINE_EXCEEDED="outcome_deadline_exceeded"})(H||(H={}));/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const $=["user","model","function","system"];var Y;(function(e){e.HARM_CATEGORY_UNSPECIFIED="HARM_CATEGORY_UNSPECIFIED",e.HARM_CATEGORY_HATE_SPEECH="HARM_CATEGORY_HATE_SPEECH",e.HARM_CATEGORY_SEXUALLY_EXPLICIT="HARM_CATEGORY_SEXUALLY_EXPLICIT",e.HARM_CATEGORY_HARASSMENT="HARM_CATEGORY_HARASSMENT",e.HARM_CATEGORY_DANGEROUS_CONTENT="HARM_CATEGORY_DANGEROUS_CONTENT"})(Y||(Y={}));var K;(function(e){e.HARM_BLOCK_THRESHOLD_UNSPECIFIED="HARM_BLOCK_THRESHOLD_UNSPECIFIED",e.BLOCK_LOW_AND_ABOVE="BLOCK_LOW_AND_ABOVE",e.BLOCK_MEDIUM_AND_ABOVE="BLOCK_MEDIUM_AND_ABOVE",e.BLOCK_ONLY_HIGH="BLOCK_ONLY_HIGH",e.BLOCK_NONE="BLOCK_NONE"})(K||(K={}));var B;(function(e){e.HARM_PROBABILITY_UNSPECIFIED="HARM_PROBABILITY_UNSPECIFIED",e.NEGLIGIBLE="NEGLIGIBLE",e.LOW="LOW",e.MEDIUM="MEDIUM",e.HIGH="HIGH"})(B||(B={}));var q;(function(e){e.BLOCKED_REASON_UNSPECIFIED="BLOCKED_REASON_UNSPECIFIED",e.SAFETY="SAFETY",e.OTHER="OTHER"})(q||(q={}));var S;(function(e){e.FINISH_REASON_UNSPECIFIED="FINISH_REASON_UNSPECIFIED",e.STOP="STOP",e.MAX_TOKENS="MAX_TOKENS",e.SAFETY="SAFETY",e.RECITATION="RECITATION",e.LANGUAGE="LANGUAGE",e.OTHER="OTHER"})(S||(S={}));var V;(function(e){e.TASK_TYPE_UNSPECIFIED="TASK_TYPE_UNSPECIFIED",e.RETRIEVAL_QUERY="RETRIEVAL_QUERY",e.RETRIEVAL_DOCUMENT="RETRIEVAL_DOCUMENT",e.SEMANTIC_SIMILARITY="SEMANTIC_SIMILARITY",e.CLASSIFICATION="CLASSIFICATION",e.CLUSTERING="CLUSTERING"})(V||(V={}));var J;(function(e){e.MODE_UNSPECIFIED="MODE_UNSPECIFIED",e.AUTO="AUTO",e.ANY="ANY",e.NONE="NONE"})(J||(J={}));var z;(function(e){e.MODE_UNSPECIFIED="MODE_UNSPECIFIED",e.MODE_DYNAMIC="MODE_DYNAMIC"})(z||(z={}));/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class f extends Error{constructor(t){super(`[GoogleGenerativeAI Error]: ${t}`)}}class A extends f{constructor(t,n){super(t),this.response=n}}class se extends f{constructor(t,n,i,s){super(t),this.status=n,this.statusText=i,this.errorDetails=s}}class m extends f{}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const ge="https://generativelanguage.googleapis.com",pe="v1beta",Ee="0.21.0",ye="genai-js";var C;(function(e){e.GENERATE_CONTENT="generateContent",e.STREAM_GENERATE_CONTENT="streamGenerateContent",e.COUNT_TOKENS="countTokens",e.EMBED_CONTENT="embedContent",e.BATCH_EMBED_CONTENTS="batchEmbedContents"})(C||(C={}));class me{constructor(t,n,i,s,o){this.model=t,this.task=n,this.apiKey=i,this.stream=s,this.requestOptions=o}toString(){var t,n;const i=((t=this.requestOptions)===null||t===void 0?void 0:t.apiVersion)||pe;let o=`${((n=this.requestOptions)===null||n===void 0?void 0:n.baseUrl)||ge}/${i}/${this.model}:${this.task}`;return this.stream&&(o+="?alt=sse"),o}}function _e(e){const t=[];return e!=null&&e.apiClient&&t.push(e.apiClient),t.push(`${ye}/${Ee}`),t.join(" ")}async function Ce(e){var t;const n=new Headers;n.append("Content-Type","application/json"),n.append("x-goog-api-client",_e(e.requestOptions)),n.append("x-goog-api-key",e.apiKey);let i=(t=e.requestOptions)===null||t===void 0?void 0:t.customHeaders;if(i){if(!(i instanceof Headers))try{i=new Headers(i)}catch(s){throw new m(`unable to convert customHeaders value ${JSON.stringify(i)} to Headers: ${s.message}`)}for(const[s,o]of i.entries()){if(s==="x-goog-api-key")throw new m(`Cannot set reserved header name ${s}`);if(s==="x-goog-api-client")throw new m(`Header name ${s} can only be set using the apiClient field`);n.append(s,o)}}return n}async function Re(e,t,n,i,s,o){const r=new me(e,t,n,i,o);return{url:r.toString(),fetchOptions:Object.assign(Object.assign({},Oe(o)),{method:"POST",headers:await Ce(r),body:s})}}async function M(e,t,n,i,s,o={},r=fetch){const{url:a,fetchOptions:d}=await Re(e,t,n,i,s,o);return we(a,d,r)}async function we(e,t,n=fetch){let i;try{i=await n(e,t)}catch(s){Ie(s,e)}return i.ok||await Ae(i,e),i}function Ie(e,t){let n=e;throw e instanceof se||e instanceof m||(n=new f(`Error fetching from ${t.toString()}: ${e.message}`),n.stack=e.stack),n}async function Ae(e,t){let n="",i;try{const s=await e.json();n=s.error.message,s.error.details&&(n+=` ${JSON.stringify(s.error.details)}`,i=s.error.details)}catch{}throw new se(`Error fetching from ${t.toString()}: [${e.status} ${e.statusText}] ${n}`,e.status,e.statusText,i)}function Oe(e){const t={};if((e==null?void 0:e.signal)!==void 0||(e==null?void 0:e.timeout)>=0){const n=new AbortController;(e==null?void 0:e.timeout)>=0&&setTimeout(()=>n.abort(),e.timeout),e!=null&&e.signal&&e.signal.addEventListener("abort",()=>{n.abort()}),t.signal=n.signal}return t}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function k(e){return e.text=()=>{if(e.candidates&&e.candidates.length>0){if(e.candidates.length>1&&console.warn(`This response had ${e.candidates.length} candidates. Returning text from the first candidate only. Access response.candidates directly to use the other candidates.`),D(e.candidates[0]))throw new A(`${E(e)}`,e);return Se(e)}else if(e.promptFeedback)throw new A(`Text not available. ${E(e)}`,e);return""},e.functionCall=()=>{if(e.candidates&&e.candidates.length>0){if(e.candidates.length>1&&console.warn(`This response had ${e.candidates.length} candidates. Returning function calls from the first candidate only. Access response.candidates directly to use the other candidates.`),D(e.candidates[0]))throw new A(`${E(e)}`,e);return console.warn("response.functionCall() is deprecated. Use response.functionCalls() instead."),W(e)[0]}else if(e.promptFeedback)throw new A(`Function call not available. ${E(e)}`,e)},e.functionCalls=()=>{if(e.candidates&&e.candidates.length>0){if(e.candidates.length>1&&console.warn(`This response had ${e.candidates.length} candidates. Returning function calls from the first candidate only. Access response.candidates directly to use the other candidates.`),D(e.candidates[0]))throw new A(`${E(e)}`,e);return W(e)}else if(e.promptFeedback)throw new A(`Function call not available. ${E(e)}`,e)},e}function Se(e){var t,n,i,s;const o=[];if(!((n=(t=e.candidates)===null||t===void 0?void 0:t[0].content)===null||n===void 0)&&n.parts)for(const r of(s=(i=e.candidates)===null||i===void 0?void 0:i[0].content)===null||s===void 0?void 0:s.parts)r.text&&o.push(r.text),r.executableCode&&o.push("\n```"+r.executableCode.language+`
`+r.executableCode.code+"\n```\n"),r.codeExecutionResult&&o.push("\n```\n"+r.codeExecutionResult.output+"\n```\n");return o.length>0?o.join(""):""}function W(e){var t,n,i,s;const o=[];if(!((n=(t=e.candidates)===null||t===void 0?void 0:t[0].content)===null||n===void 0)&&n.parts)for(const r of(s=(i=e.candidates)===null||i===void 0?void 0:i[0].content)===null||s===void 0?void 0:s.parts)r.functionCall&&o.push(r.functionCall);if(o.length>0)return o}const be=[S.RECITATION,S.SAFETY,S.LANGUAGE];function D(e){return!!e.finishReason&&be.includes(e.finishReason)}function E(e){var t,n,i;let s="";if((!e.candidates||e.candidates.length===0)&&e.promptFeedback)s+="Response was blocked",!((t=e.promptFeedback)===null||t===void 0)&&t.blockReason&&(s+=` due to ${e.promptFeedback.blockReason}`),!((n=e.promptFeedback)===null||n===void 0)&&n.blockReasonMessage&&(s+=`: ${e.promptFeedback.blockReasonMessage}`);else if(!((i=e.candidates)===null||i===void 0)&&i[0]){const o=e.candidates[0];D(o)&&(s+=`Candidate was blocked due to ${o.finishReason}`,o.finishMessage&&(s+=`: ${o.finishMessage}`))}return s}function v(e){return this instanceof v?(this.v=e,this):new v(e)}function Te(e,t,n){if(!Symbol.asyncIterator)throw new TypeError("Symbol.asyncIterator is not defined.");var i=n.apply(e,t||[]),s,o=[];return s={},r("next"),r("throw"),r("return"),s[Symbol.asyncIterator]=function(){return this},s;function r(l){i[l]&&(s[l]=function(c){return new Promise(function(u,I){o.push([l,c,u,I])>1||a(l,c)})})}function a(l,c){try{d(i[l](c))}catch(u){w(o[0][3],u)}}function d(l){l.value instanceof v?Promise.resolve(l.value.v).then(g,R):w(o[0][2],l)}function g(l){a("next",l)}function R(l){a("throw",l)}function w(l,c){l(c),o.shift(),o.length&&a(o[0][0],o[0][1])}}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const X=/^data\: (.*)(?:\n\n|\r\r|\r\n\r\n)/;function Ne(e){const t=e.body.pipeThrough(new TextDecoderStream("utf8",{fatal:!0})),n=Me(t),[i,s]=n.tee();return{stream:xe(i),response:ve(s)}}async function ve(e){const t=[],n=e.getReader();for(;;){const{done:i,value:s}=await n.read();if(i)return k(De(t));t.push(s)}}function xe(e){return Te(this,arguments,function*(){const n=e.getReader();for(;;){const{value:i,done:s}=yield v(n.read());if(s)break;yield yield v(k(i))}})}function Me(e){const t=e.getReader();return new ReadableStream({start(i){let s="";return o();function o(){return t.read().then(({value:r,done:a})=>{if(a){if(s.trim()){i.error(new f("Failed to parse stream"));return}i.close();return}s+=r;let d=s.match(X),g;for(;d;){try{g=JSON.parse(d[1])}catch{i.error(new f(`Error parsing JSON response: "${d[1]}"`));return}i.enqueue(g),s=s.substring(d[0].length),d=s.match(X)}return o()})}}})}function De(e){const t=e[e.length-1],n={promptFeedback:t==null?void 0:t.promptFeedback};for(const i of e){if(i.candidates)for(const s of i.candidates){const o=s.index;if(n.candidates||(n.candidates=[]),n.candidates[o]||(n.candidates[o]={index:s.index}),n.candidates[o].citationMetadata=s.citationMetadata,n.candidates[o].groundingMetadata=s.groundingMetadata,n.candidates[o].finishReason=s.finishReason,n.candidates[o].finishMessage=s.finishMessage,n.candidates[o].safetyRatings=s.safetyRatings,s.content&&s.content.parts){n.candidates[o].content||(n.candidates[o].content={role:s.content.role||"user",parts:[]});const r={};for(const a of s.content.parts)a.text&&(r.text=a.text),a.functionCall&&(r.functionCall=a.functionCall),a.executableCode&&(r.executableCode=a.executableCode),a.codeExecutionResult&&(r.codeExecutionResult=a.codeExecutionResult),Object.keys(r).length===0&&(r.text=""),n.candidates[o].content.parts.push(r)}}i.usageMetadata&&(n.usageMetadata=i.usageMetadata)}return n}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function oe(e,t,n,i){const s=await M(t,C.STREAM_GENERATE_CONTENT,e,!0,JSON.stringify(n),i);return Ne(s)}async function re(e,t,n,i){const o=await(await M(t,C.GENERATE_CONTENT,e,!1,JSON.stringify(n),i)).json();return{response:k(o)}}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */function ae(e){if(e!=null){if(typeof e=="string")return{role:"system",parts:[{text:e}]};if(e.text)return{role:"system",parts:[e]};if(e.parts)return e.role?e:{role:"system",parts:e.parts}}}function x(e){let t=[];if(typeof e=="string")t=[{text:e}];else for(const n of e)typeof n=="string"?t.push({text:n}):t.push(n);return Ge(t)}function Ge(e){const t={role:"user",parts:[]},n={role:"function",parts:[]};let i=!1,s=!1;for(const o of e)"functionResponse"in o?(n.parts.push(o),s=!0):(t.parts.push(o),i=!0);if(i&&s)throw new f("Within a single message, FunctionResponse cannot be mixed with other type of part in the request for sending chat message.");if(!i&&!s)throw new f("No content is provided for sending chat message.");return i?t:n}function Le(e,t){var n;let i={model:t==null?void 0:t.model,generationConfig:t==null?void 0:t.generationConfig,safetySettings:t==null?void 0:t.safetySettings,tools:t==null?void 0:t.tools,toolConfig:t==null?void 0:t.toolConfig,systemInstruction:t==null?void 0:t.systemInstruction,cachedContent:(n=t==null?void 0:t.cachedContent)===null||n===void 0?void 0:n.name,contents:[]};const s=e.generateContentRequest!=null;if(e.contents){if(s)throw new m("CountTokensRequest must have one of contents or generateContentRequest, not both.");i.contents=e.contents}else if(s)i=Object.assign(Object.assign({},i),e.generateContentRequest);else{const o=x(e);i.contents=[o]}return{generateContentRequest:i}}function Q(e){let t;return e.contents?t=e:t={contents:[x(e)]},e.systemInstruction&&(t.systemInstruction=ae(e.systemInstruction)),t}function ke(e){return typeof e=="string"||Array.isArray(e)?{content:x(e)}:e}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const Z=["text","inlineData","functionCall","functionResponse","executableCode","codeExecutionResult"],Ue={user:["text","inlineData"],function:["functionResponse"],model:["text","functionCall","executableCode","codeExecutionResult"],system:["text"]};function Fe(e){let t=!1;for(const n of e){const{role:i,parts:s}=n;if(!t&&i!=="user")throw new f(`First content should be with role 'user', got ${i}`);if(!$.includes(i))throw new f(`Each item should include role field. Got ${i} but valid roles are: ${JSON.stringify($)}`);if(!Array.isArray(s))throw new f("Content should have 'parts' property with an array of Parts");if(s.length===0)throw new f("Each Content should have at least one part");const o={text:0,inlineData:0,functionCall:0,functionResponse:0,fileData:0,executableCode:0,codeExecutionResult:0};for(const a of s)for(const d of Z)d in a&&(o[d]+=1);const r=Ue[i];for(const a of Z)if(!r.includes(a)&&o[a]>0)throw new f(`Content with role '${i}' can't contain '${a}' part`);t=!0}}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */const ee="SILENT_ERROR";class Pe{constructor(t,n,i,s={}){this.model=n,this.params=i,this._requestOptions=s,this._history=[],this._sendPromise=Promise.resolve(),this._apiKey=t,i!=null&&i.history&&(Fe(i.history),this._history=i.history)}async getHistory(){return await this._sendPromise,this._history}async sendMessage(t,n={}){var i,s,o,r,a,d;await this._sendPromise;const g=x(t),R={safetySettings:(i=this.params)===null||i===void 0?void 0:i.safetySettings,generationConfig:(s=this.params)===null||s===void 0?void 0:s.generationConfig,tools:(o=this.params)===null||o===void 0?void 0:o.tools,toolConfig:(r=this.params)===null||r===void 0?void 0:r.toolConfig,systemInstruction:(a=this.params)===null||a===void 0?void 0:a.systemInstruction,cachedContent:(d=this.params)===null||d===void 0?void 0:d.cachedContent,contents:[...this._history,g]},w=Object.assign(Object.assign({},this._requestOptions),n);let l;return this._sendPromise=this._sendPromise.then(()=>re(this._apiKey,this.model,R,w)).then(c=>{var u;if(c.response.candidates&&c.response.candidates.length>0){this._history.push(g);const I=Object.assign({parts:[],role:"model"},(u=c.response.candidates)===null||u===void 0?void 0:u[0].content);this._history.push(I)}else{const I=E(c.response);I&&console.warn(`sendMessage() was unsuccessful. ${I}. Inspect response object for details.`)}l=c}),await this._sendPromise,l}async sendMessageStream(t,n={}){var i,s,o,r,a,d;await this._sendPromise;const g=x(t),R={safetySettings:(i=this.params)===null||i===void 0?void 0:i.safetySettings,generationConfig:(s=this.params)===null||s===void 0?void 0:s.generationConfig,tools:(o=this.params)===null||o===void 0?void 0:o.tools,toolConfig:(r=this.params)===null||r===void 0?void 0:r.toolConfig,systemInstruction:(a=this.params)===null||a===void 0?void 0:a.systemInstruction,cachedContent:(d=this.params)===null||d===void 0?void 0:d.cachedContent,contents:[...this._history,g]},w=Object.assign(Object.assign({},this._requestOptions),n),l=oe(this._apiKey,this.model,R,w);return this._sendPromise=this._sendPromise.then(()=>l).catch(c=>{throw new Error(ee)}).then(c=>c.response).then(c=>{if(c.candidates&&c.candidates.length>0){this._history.push(g);const u=Object.assign({},c.candidates[0].content);u.role||(u.role="model"),this._history.push(u)}else{const u=E(c);u&&console.warn(`sendMessageStream() was unsuccessful. ${u}. Inspect response object for details.`)}}).catch(c=>{c.message!==ee&&console.error(c)}),l}}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function je(e,t,n,i){return(await M(t,C.COUNT_TOKENS,e,!1,JSON.stringify(n),i)).json()}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */async function He(e,t,n,i){return(await M(t,C.EMBED_CONTENT,e,!1,JSON.stringify(n),i)).json()}async function $e(e,t,n,i){const s=n.requests.map(r=>Object.assign(Object.assign({},r),{model:t}));return(await M(t,C.BATCH_EMBED_CONTENTS,e,!1,JSON.stringify({requests:s}),i)).json()}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class te{constructor(t,n,i={}){this.apiKey=t,this._requestOptions=i,n.model.includes("/")?this.model=n.model:this.model=`models/${n.model}`,this.generationConfig=n.generationConfig||{},this.safetySettings=n.safetySettings||[],this.tools=n.tools,this.toolConfig=n.toolConfig,this.systemInstruction=ae(n.systemInstruction),this.cachedContent=n.cachedContent}async generateContent(t,n={}){var i;const s=Q(t),o=Object.assign(Object.assign({},this._requestOptions),n);return re(this.apiKey,this.model,Object.assign({generationConfig:this.generationConfig,safetySettings:this.safetySettings,tools:this.tools,toolConfig:this.toolConfig,systemInstruction:this.systemInstruction,cachedContent:(i=this.cachedContent)===null||i===void 0?void 0:i.name},s),o)}async generateContentStream(t,n={}){var i;const s=Q(t),o=Object.assign(Object.assign({},this._requestOptions),n);return oe(this.apiKey,this.model,Object.assign({generationConfig:this.generationConfig,safetySettings:this.safetySettings,tools:this.tools,toolConfig:this.toolConfig,systemInstruction:this.systemInstruction,cachedContent:(i=this.cachedContent)===null||i===void 0?void 0:i.name},s),o)}startChat(t){var n;return new Pe(this.apiKey,this.model,Object.assign({generationConfig:this.generationConfig,safetySettings:this.safetySettings,tools:this.tools,toolConfig:this.toolConfig,systemInstruction:this.systemInstruction,cachedContent:(n=this.cachedContent)===null||n===void 0?void 0:n.name},t),this._requestOptions)}async countTokens(t,n={}){const i=Le(t,{model:this.model,generationConfig:this.generationConfig,safetySettings:this.safetySettings,tools:this.tools,toolConfig:this.toolConfig,systemInstruction:this.systemInstruction,cachedContent:this.cachedContent}),s=Object.assign(Object.assign({},this._requestOptions),n);return je(this.apiKey,this.model,i,s)}async embedContent(t,n={}){const i=ke(t),s=Object.assign(Object.assign({},this._requestOptions),n);return He(this.apiKey,this.model,i,s)}async batchEmbedContents(t,n={}){const i=Object.assign(Object.assign({},this._requestOptions),n);return $e(this.apiKey,this.model,t,i)}}/**
 * @license
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */class ce{constructor(t){this.apiKey=t}getGenerativeModel(t,n){if(!t.model)throw new f("Must provide a model name. Example: genai.getGenerativeModel({ model: 'my-model-name' })");return new te(this.apiKey,t,n)}getGenerativeModelFromCachedContent(t,n,i){if(!t.name)throw new m("Cached content must contain a `name` field.");if(!t.model)throw new m("Cached content must contain a `model` field.");const s=["model","systemInstruction"];for(const r of s)if(n!=null&&n[r]&&t[r]&&(n==null?void 0:n[r])!==t[r]){if(r==="model"){const a=n.model.startsWith("models/")?n.model.replace("models/",""):n.model,d=t.model.startsWith("models/")?t.model.replace("models/",""):t.model;if(a===d)continue}throw new m(`Different value for "${r}" specified in modelParams (${n[r]}) and cachedContent (${t[r]})`)}const o=Object.assign(Object.assign({},n),{model:t.model,tools:t.tools,toolConfig:t.toolConfig,systemInstruction:t.systemInstruction,cachedContent:t});return new te(this.apiKey,o,i)}}const G=fe("GeminiApiService");let h="AIzaSyBAScrXEbuOKBbNpIog02_tpcXuYdPXeO0";!h&&typeof window<"u"&&typeof localStorage<"u"&&(h=localStorage.getItem("riffRap-gemini-api-key"),h||(h=localStorage.getItem("riffrap-gemini-api-key")),!h&&window.VITE_GEMINI_API_KEY&&(h=window.VITE_GEMINI_API_KEY));if(!h){const e=new p("Gemini API key not found. Please set it in the settings.",{code:"ERR_API_KEY",context:{component:"GeminiApiService"}});if(N.handleError(e,{notify:!0,rethrow:!1}),typeof window<"u"&&window.soundsEnabled)try{window.soundService&&window.soundService.playErrorSound&&window.soundService.playErrorSound()}catch(t){G.warn("Could not play error sound",t)}}const de=new ce(h||""),U=de.getGenerativeModel({model:"gemini-2.0-flash-exp"});let b=!1,_=null;function ne(){return b||_||(G.info("Preloading speech model for faster response"),_=U.generateContent("hello").then(e=>(G.info("Speech model preloaded successfully"),b=!0,e)).catch(e=>{const t=new p("Error preloading speech model",{code:"ERR_API_PRELOAD",context:{originalError:e.message},isOperational:!0});throw N.handleError(t,{notify:!1,rethrow:!1}),_=null,t})),_}function Ye(e){return new Promise((t,n)=>{if(!e||!(e instanceof Blob)){n(new p("Invalid blob provided",{code:"ERR_API_INVALID_BLOB",context:{blobType:e?typeof e:"null"}}));return}const i=new FileReader;i.onloadend=()=>{try{const s=i.result.split(",")[1];t({inlineData:{data:s,mimeType:e.type}})}catch(s){n(new p("Error processing blob",{code:"ERR_API_BLOB_PROCESSING",context:{originalError:s.message}}))}},i.onerror=()=>{n(new p("Error reading file",{code:"ERR_API_FILE_READ",context:{fileType:e.type,fileSize:e.size}}))},i.readAsDataURL(e)})}const Ke=N.wrapAsync(async e=>{if(!h)throw new p("API key is required for content generation",{code:"ERR_API_KEY_REQUIRED"});try{return(await U.generateContent(e)).response}catch(t){throw new p("Failed to generate content with Gemini",{code:"ERR_API_GENERATION",context:{originalError:t.message,modelName:"gemini-2.0-flash-exp"}})}},{notify:!0,rethrow:!0}),We={preloadModel:ne,blobToGenerativePart:Ye,generateContent:Ke,getModelStatus(){return{initialized:b,initializing:!!_&&!b,hasApiKey:!!h}},updateApiKey(e){if(!e||typeof e!="string"||e.trim()==="")return Promise.reject(N.handleError(new p("Invalid API key provided",{code:"ERR_API_KEY_INVALID",context:{keyType:typeof e}}),{notify:!0,rethrow:!0}));try{h=e;const t=new ce(h),n=t.getGenerativeModel({model:"gemini-2.0-flash-exp"});return Object.assign(de,t),Object.assign(U,n),b=!1,_=null,G.info("API key updated successfully, preloading model with new key"),ne()}catch(t){return Promise.reject(N.handleError(new p("Failed to initialize API client with new key",{code:"ERR_API_INIT",context:{originalError:t.message}}),{notify:!0,rethrow:!0}))}}},y={standard:{transcribeAudio:{text:"Transcribe this audio as accurately as possible. When words are unclear or mumbled, use your best judgment but avoid over-interpreting or adding creative embellishments. If something is truly unintelligible, leave it as [unclear] rather than guessing. Remove obvious filler words ('um', 'uh', 'like') but preserve the natural flow and phrasing. Format with line breaks at natural pause points and breath marks. Group related lines that flow together into sections separated by blank lines - this creates chunks that represent complete thoughts or musical phrases. Focus on honest transcription of what was actually said or sung. Return only the formatted text with no additional commentary."},generateAnimation:{text:`Generate a CSS animation for a ghost SVG based on this description: '{{description}}'. Return a JSON object with the following structure:

{
  "name": "unique-animation-name", // A unique, descriptive kebab-case name for the animation
  "target": "whole" or "eyes" or "bg" or "outline", // Which part of the ghost to animate. Default to 'whole' if not specified in the description
  "duration": value in seconds, // Reasonable animation duration (0.5-3s)
  "timing": "ease"/"linear"/"cubic-bezier(x,x,x,x)", // Appropriate timing function
  "iteration": number or "infinite", // How many times to play (usually 1 or infinite)
  "keyframes": [
    {
      "percentage": 0, // Keyframe percentage (0-100)
      "properties": { // CSS properties to animate
        "transform": "...", // Any transform functions
        "opacity": value, // Opacity value if needed
        // Other properties as needed
      }
    },
    // More keyframes as needed
  ],
  "description": "Short description of what this animation does"
}

Critical requirements:
1. Make sure the animation is visually appealing and matches the description
2. Use ONLY transform properties (scale, rotate, translate, etc.) and opacity for animation
3. Avoid properties that would break the SVG (like background-color)
4. Ensure animation starts and ends in a natural state (if not infinite)
5. If the animation should affect only part of the ghost, specify the correct 'target'
6. Ensure all values are valid CSS
7. DO NOT include any explanation or text outside the JSON object
8. VERY IMPORTANT: Return raw JSON only - DO NOT use markdown formatting, code blocks, or backticks (\`\`\`) in your response`}},lyricsMode:{transcribeAudio:{text:"Transform this audio into well-formatted song lyrics. If there are no clear vocals, silence, or just random sounds where no lyrics can be discerned, simply return exactly: 'No lyrical vibes received!' and nothing else. For actual vocal content: (1) Preserve the exact words and vocal rhythm from the recording, (2) Format with proper line breaks at natural phrase endings, (3) Add blank lines between different sections (verse/chorus/bridge), (4) Create clear paragraph breaks between verses, (5) Use consistent formatting for repeated sections. Do not add any markdown formatting, special characters, or stylistic modifications. Focus purely on transcribing the words with proper spacing and line breaks. Do not enhance or modify the actual words - just clean up filler sounds while preserving the natural flow and phrasing. Return only the formatted lyrics with no additional text, explanation, or styling. Preserve all whitespace and line breaks in your response."}},leetSpeak:{transcribeAudio:{text:"Tr4n5cr1b3 th15 4ud10 f1l3 4ccur4t3ly, but c0nv3rt 1t 1nt0 l33t 5p34k. U53 num3r1c 5ub5t1tut10n5 (3=e, 4=a, 1=i, 0=o, 5=s, 7=t) 4nd h4ck3r j4rg0n wh3n p0551bl3. R3turn 0nly th3 l33t 5p34k tr4n5cr1pt10n, n0 4dd1t10n4l t3xt."}},sparklePop:{transcribeAudio:{text:"OMG!!! Transcribe this audio file like TOTALLY accurately, but make it SUPER bubbly and enthusiastic!!! Use LOTS of emojis, exclamation points, and teen slang!!!! Sprinkle in words like 'literally,' 'totally,' 'sooo,' 'vibes,' and 'obsessed'!!! Add sparkle emojis ✨, hearts 💖, and rainbow emojis 🌈 throughout!!! Make it EXTRA and over-the-top excited!!!"}},codeWhisperer:{transcribeAudio:{text:"Transcribe this audio file accurately and completely, but reformat it into clear, structured, technical language suitable for a coding prompt. Remove redundancies, organize thoughts logically, use precise technical terminology, and structure content with clear sections. Return only the optimized, programmer-friendly transcription."}},quillAndInk:{transcribeAudio:{text:"Transcribe this audio file with the eloquence and stylistic flourishes of a 19th century Victorian novelist, in the vein of Jane Austen or Charles Dickens. Employ elaborate sentences, period-appropriate vocabulary, literary devices, and a generally formal and ornate prose style. The transcription should maintain the original meaning but transform the manner of expression entirely."}}};function ie(e,t){let n=e;return Object.entries(t).forEach(([i,s])=>{const o=new RegExp(`{{${i}}}`,"g");n=n.replace(o,s)}),n}const L="riffrap-prompt-style",T="standard",Be=()=>{const e=he(T);{const t=localStorage.getItem(L);t&&y[t]?e.set(t):t&&!y[t]&&(localStorage.setItem(L,T),e.set(T))}return{...e,setStyle:t=>y[t]?(e.set(t),localStorage.setItem(L,t),!0):(console.error(`Prompt style '${t}' not found`),!1),getAvailableStyles:()=>Object.keys(y)}},O=Be(),Xe={getCurrentStyle:()=>F(O),setStyle:e=>O.setStyle(e),getAvailableStyles:()=>O.getAvailableStyles(),getPrompt:(e,t={})=>{let n=F(O);return y[n]||(console.error(`Prompt style '${n}' not found, falling back to standard`),n=T,O.setStyle(T)),y[n][e]?ie(y[n][e].text,t):(console.error(`Operation '${e}' not found in style '${n}', falling back to standard`),ie(y.standard[e].text,t))},subscribe:e=>O.subscribe(e)};export{ze as b,We as g,Xe as p};
