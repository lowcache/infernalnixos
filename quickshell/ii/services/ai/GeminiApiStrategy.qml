import QtQuick
import qs.modules.common.functions as CF

ApiStrategy {
    readonly property string apiKeyEnvVarName: "API_KEY"
    readonly property string fileUriVarName: "file_uri"
    readonly property string fileMimeTypeVarName: "MIME_TYPE"
    readonly property string fileUriSubstitutionString: "{{ fileUriVarName }}"
    readonly property string fileMimeTypeSubstitutionString: "{{ fileMimeTypeVarName }}"
    property string buffer: ""
    
    function buildEndpoint(model: AiModel): string {
        const result = model.endpoint + `?key=\$\{${root.apiKeyEnvVarName}\}`
        // console.log("[AI] Endpoint: " + result);
        return result;
    }

    function buildRequestData(model: AiModel, messages, systemPrompt: string, temperature: real, tools: list<var>, filePath: string) {
        let contents = messages.map(message => {
            // console.log("[AI] Building request data for message:", JSON.stringify(message, null, 2));
            const geminiApiRoleName = (message.role === "assistant") ? "model" : message.role;
            const usingSearch = tools[0]?.google_search !== undefined
            let parts = []

            if (!usingSearch && message.functionCall != undefined && message.functionName.length > 0) {
                let fcPart = {
                    functionCall: {
                        "name": message.functionName,
                        "args": message.functionCall.args || {}
                    }
                };
                if (message.thoughtSignature && message.thoughtSignature.length > 0) {
                    fcPart.thoughtSignature = message.thoughtSignature;
                }
                parts.push(fcPart);
                return {
                    "role": geminiApiRoleName,
                    "parts": parts
                };
            }

            if (!usingSearch && message.functionResponse != undefined && message.functionName.length > 0) {
                parts.push({ 
                    functionResponse: {
                        "name": message.functionName,
                        "response": { "content": message.functionResponse }
                    }
                });
                return {
                    "role": geminiApiRoleName,
                    "parts": parts
                };
            }

            let textPart = { text: message.rawContent || "" };
            if (message.thoughtSignature && message.thoughtSignature.length > 0) {
                textPart.thoughtSignature = message.thoughtSignature;
            }
            parts.push(textPart);
            if (message.fileUri && message.fileUri.length > 0) {
                parts.push({ 
                    "file_data": {
                        "mime_type": message.fileMimeType,
                        "file_uri": message.fileUri
                    }
                })
            }
            return {
                "role": geminiApiRoleName,
                "parts": parts
            }
        })
        if (filePath && filePath.length > 0) {
            const trimmedFilePath = CF.FileUtils.trimFileProtocol(filePath);
            // Add file_data part to the last message's parts array
            contents[contents.length - 1].parts.unshift({
                file_data: {
                    mime_type: fileMimeTypeSubstitutionString,
                    file_uri: fileUriSubstitutionString
                }
            });
        }
        let baseData = {
            "contents": contents,
            "tools": tools,
            "system_instruction": {
                "parts": [{ text: systemPrompt }]
            },
            "generationConfig": {
                "temperature": temperature,
            },
        };
        // print("Gemini API call payload:", JSON.stringify(baseData, null, 2));
        return model.extraParams ? Object.assign({}, baseData, model.extraParams) : baseData;
    }

    function buildAuthorizationHeader(apiKeyEnvVarName: string): string {
        // Gemini doesn't use Authorization header, key is in URL
        return "";
    }

    function parseResponseLine(line, message) {
        let trimmedLine = line.trim();
        if (trimmedLine.startsWith("[")) {
            trimmedLine = trimmedLine.slice(1).trim();
        }
        if (trimmedLine.startsWith(",")) {
            trimmedLine = trimmedLine.slice(1).trim();
        }
        if (trimmedLine.endsWith("]")) {
            // Check if it's the end of the array, but be careful not to slice 
            // if it's just a JSON object ending with ] (unlikely for Gemini but good practice)
            // Gemini streams are typically [ {obj}, {obj} ]
            if (trimmedLine === "]") {
                trimmedLine = "";
            } else {
                trimmedLine = trimmedLine.slice(0, -1).trim();
            }
        }
        
        if (trimmedLine.length > 0) {
            buffer += trimmedLine;
            return parseBuffer(message);
        }
        return {};
    }

    function parseBuffer(message) {
        // console.log("[Ai] Gemini buffer: ", buffer);
        let finished = false;
        try {
            if (buffer.length === 0) return {};
            const dataJson = JSON.parse(buffer);

            // Uploaded file
            if (dataJson.uploadedFile) {
                message.fileUri = dataJson.uploadedFile.uri;
                message.fileMimeType = dataJson.uploadedFile.mimeType;
                return ({})
            }

            // Error response handling
            if (dataJson.error) {
                const errorMsg = `**Error ${dataJson.error.code}**: ${dataJson.error.message}`;
                message.rawContent += errorMsg;
                message.content += errorMsg;
                return { finished: true };
            }

            // No candidates?
            if (!dataJson.candidates) return {};
            
            // Finished?
            if (dataJson.candidates[0]?.finishReason) {
                finished = true;
            }

            // Thought and thought signature handling
            const parts = dataJson.candidates[0]?.content?.parts || [];
            let functionCallData = null;
            parts.forEach(part => {
                if (part.thoughtSignature) {
                    message.thoughtSignature = part.thoughtSignature;
                }
                if (part.thought) {
                    message.thought = part.thought;
                    // This is unencrypted reasoning text (Gemini 2.0 Thinking). 
                    // Wrap it in <think> tags for the UI to render it as a reasoning block.
                    if (!message.rawContent.includes("<think>")) {
                        message.rawContent += "<think>\n";
                        message.content += "<think>\n";
                    }
                    message.rawContent += part.thought;
                    message.content += part.thought;
                }
                if (part.functionCall || part.text) {
                    // Close think block if it's open
                    if (message.rawContent.includes("<think>") && !message.rawContent.includes("</think>")) {
                        message.rawContent += "\n</think>\n\n";
                        message.content += "\n</think>\n\n";
                    }

                    if (part.functionCall) {
                        const functionCall = part.functionCall;
                        message.functionName = functionCall.name;
                        message.functionCall = functionCall; // Store full object with args
                        const newContent = `\n\n[[ Function: ${functionCall.name}(${JSON.stringify(functionCall.args, null, 2)}) ]]\n`
                        message.rawContent += newContent;
                        message.content += newContent;
                        functionCallData = { name: functionCall.name, args: functionCall.args };
                    }
                    if (part.text) {
                        message.rawContent += part.text;
                        message.content += part.text;
                    }
                }
            });
            
            // Usage metadata
            const annotationSources = dataJson.candidates[0]?.groundingMetadata?.groundingChunks?.map(chunk => {
                return {
                    "type": "url_citation",
                    "text": chunk?.web?.title,
                    "url": chunk?.web?.uri,
                }
            }) ?? [];

            const annotations = dataJson.candidates[0]?.groundingMetadata?.groundingSupports?.map(citation => {
                return {
                    "type": "url_citation",
                    "start_index": citation.segment?.startIndex,
                    "end_index": citation.segment?.endIndex,
                    "text": citation?.segment.text,
                    "url": annotationSources[citation.groundingChunkIndices[0]]?.url,
                    "sources": citation.groundingChunkIndices
                }
            });
            message.annotationSources = annotationSources;
            message.annotations = annotations;
            message.searchQueries = dataJson.candidates[0]?.groundingMetadata?.webSearchQueries ?? [];

            // Usage metadata
            let result = {
                functionCall: functionCallData,
                finished: finished
            };

            if (dataJson.usageMetadata) {
                result.tokenUsage = {
                    input: dataJson.usageMetadata.promptTokenCount ?? -1,
                    output: dataJson.usageMetadata.candidatesTokenCount ?? -1,
                    total: dataJson.usageMetadata.totalTokenCount ?? -1
                };
            }
            
            buffer = ""; // Only clear buffer if parsing succeeded
            return result;
            
        } catch (e) {
            // console.log("[AI] Gemini: Could not parse buffer: ", e);
            // If it failed to parse, it might be a partial chunk.
            // Don't clear the buffer, and don't append to message content.
            return { finished: false };
        }
    }

    function onRequestFinished(message) {
        return parseBuffer(message);
    }
    
    function reset() {
        buffer = "";
    }

    function buildScriptFileSetup(filePath) {
        const trimmedFilePath = CF.FileUtils.trimFileProtocol(filePath);
        let content = ""

        // print("file path:", filePath)
        // print("trimmed file path:", trimmedFilePath)
        // print("escaped file path:", CF.StringUtils.shellSingleQuoteEscape(trimmedFilePath))

        content += `IMAGE_PATH='${CF.StringUtils.shellSingleQuoteEscape(trimmedFilePath)}'\n`;
        content += `${fileMimeTypeVarName}=$(file -b --mime-type "$IMAGE_PATH")\n`;
        content += 'NUM_BYTES=$(wc -c < "${IMAGE_PATH}")\n';
        content += 'tmp_header_file="/tmp/quickshell/ai/upload-header.tmp"\n';
        content += 'tmp_file_info_file="/tmp/quickshell/ai/file-info.json.tmp"\n';

        // Initial resumable request defining metadata.
        // The upload url is in the response headers dump them to a file.
        content += 'curl "https://generativelanguage.googleapis.com/upload/v1beta/files"'
            + ` -H "x-goog-api-key: \$${apiKeyEnvVarName}"`
            + ' -D $tmp_header_file'
            + ' -H "X-Goog-Upload-Protocol: resumable"'
            + ' -H "X-Goog-Upload-Command: start"'
            + ' -H "X-Goog-Upload-Header-Content-Length: ${NUM_BYTES}"'
            + ` -H "X-Goog-Upload-Header-Content-Type: \${${fileMimeTypeVarName}}"`
            + ' -H "Content-Type: application/json"'
            + ` -d "{'file': {'display_name': 'Image'}}" 2> /dev/null`
            + '\n';

        // Get file upload header
        content += 'upload_url=$(grep -i "x-goog-upload-url: " "${tmp_header_file}" | cut -d" " -f2 | tr -d "\r")\n';
        content += 'rm "${tmp_header_file}"\n';

        // Upload the actual file
        content += 'curl "${upload_url}"'
            + ` -H "x-goog-api-key: \$${apiKeyEnvVarName}"`
            + ' -H "Content-Length: ${NUM_BYTES}"'
            + ' -H "X-Goog-Upload-Offset: 0"'
            + ' -H "X-Goog-Upload-Command: upload, finalize"'
            + ' --data-binary "@${IMAGE_PATH}" 2> /dev/null > "${tmp_file_info_file}"'
            + '\n';

        content += `${fileUriVarName}=$(jq -r ".file.uri" "$tmp_file_info_file")\n`
        content += `printf "{\\"uploadedFile\\": {\\"uri\\": \\"$${fileUriVarName}\\", \\"mimeType\\": \\"$${fileMimeTypeVarName}\\"}}\\n,\\n"\n`

        return content
    }

    function finalizeScriptContent(scriptContent: string): string {
        return scriptContent.replace(fileMimeTypeSubstitutionString, `'"\$${fileMimeTypeVarName}"'`)
                            .replace(fileUriSubstitutionString, `'"\$${fileUriVarName}"'`);
    }
}
