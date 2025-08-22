-- DEVONthink Smart Rule → External Script
-- Writes a concise structured summary into Spotlight Comment

use AppleScript version "2.7"
use scripting additions

-- Note: Set your OpenAI API key and model here. This script is compatible with AppleScript 2.8
property openAIAPIKey : "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"
property openAIModel : "gpt-5"

on performSmartRule(theRecords)
  tell application id "DNtp"
    repeat with theRecord in theRecords
      try
        set docText to plain text of theRecord
        if docText is missing value or docText = "" then
          log message "No text to summarize for: " & (name of theRecord) in theRecord
        else
          if (length of docText) > 20000 then set docText to text 1 thru 20000 of docText

          -- Construct the structured prompt
          set promptHead to "Before summarizing, follow this structured approach:" & return & ¬
            "1. UNDERSTAND - Identify the document's main topic and purpose (e.g. what type of file it is and its core subject)." & return & ¬
            "2. ANALYZE - Outline the key points, important details, and components presented in the document." & return & ¬
            "3. REASON - Consider how these points relate to each other and why they are important to the document's overall meaning." & return & ¬
            "4. SYNTHESIZE - Combine the above insights into a coherent understanding, noting how the elements come together as a whole." & return & ¬
            "5. CONCLUDE - Formulate the clearest, most accurate summary of the document in a concise paragraph. Make sure the summary is clear and helpful for recognizing what the document is about." & return & return & ¬
            "Now provide the final summary in a concise, easy-to-understand format, ensuring it captures the document's key content and significance for quick reference and organization." & return & return & ¬
            "Document text:" & return

          set fullPrompt to promptHead & docText
          set escapedPrompt to my jsonEscape(fullPrompt)

          -- Build JSON payload for chat completion
          set jsonPayload to "{\"model\":\"" & openAIModel & "\",\"messages\":[{\"role\":\"user\",\"content\":\"" & escapedPrompt & "\"}],\"max_tokens\":700,\"temperature\":0.2}"

          -- Prepare curl command
          set curlCmd to "curl -sS -X POST https://api.openai.com/v1/chat/completions " & ¬
            "-H 'Content-Type: application/json' " & ¬
            "-H 'Authorization: Bearer " & openAIAPIKey & "' " & ¬
            "--data-binary " & quoted form of jsonPayload

          set rawResponse to do shell script curlCmd
          if rawResponse contains "\"error\":" then
            log message "OpenAI error for: " & (name of theRecord) & " → " & rawResponse in theRecord
          else
            set summary to my extractAssistantContent(rawResponse)
            if summary is not missing value and summary is not "" then
              set comment of theRecord to summary
              log message "Summary added to: " & (name of theRecord) in theRecord
            else
              log message "No summary parsed for: " & (name of theRecord) in theRecord
            end if
          end if
        end if
      on error errMsg number errNum
        log message "Summarizer error (" & errNum & "): " & errMsg in theRecord
      end try
    end repeat
  end tell
end performSmartRule

on jsonEscape(t)
  set _text to t as text
  set astid to AppleScript's text item delimiters
  set AppleScript's text item delimiters to "\\"
  set _text to (text items of _text) as text
  set AppleScript's text item delimiters to "\\\\"
  set _text to (text items of _text) as text
  set AppleScript's text item delimiters to "\""
  set _text to (text items of _text) as text
  set AppleScript's text item delimiters to "\\\""
  set _text to (text items of _text) as text
  set AppleScript's text item delimiters to return
  set _text to (text items of _text) as text
  set AppleScript's text item delimiters to "\\n"
  set _text to (text items of _text) as text
  set AppleScript's text item delimiters to astid
  return _text
end jsonEscape

on extractAssistantContent(jsonString)
  try
    set astid to AppleScript's text item delimiters
    set AppleScript's text item delimiters to "\"content\":\""
    set parts to text items of jsonString
    if (count of parts) > 1 then
      set AppleScript's text item delimiters to "\""
      set seg to text item 2 of parts
      set contentText to text item 1 of seg
      set AppleScript's text item delimiters to astid
      set contentText to my unescapeJSON(contentText)
      return contentText
    end if
    set AppleScript's text item delimiters to astid
  end try
  return ""
end extractAssistantContent

on unescapeJSON(s)
  set _s to s as text
  set astid to AppleScript's text item delimiters
  set AppleScript's text item delimiters to "\\n"
  set _s to (text items of _s) as text
  set AppleScript's text item delimiters to return
  set _s to (text items of _s) as text
  set AppleScript's text item delimiters to "\\\""
  set _s to (text items of _s) as text
  set AppleScript's text item delimiters to "\""
  set _s to (text items of _s) as text
  set AppleScript's text item delimiters to "\\\\"
  set _s to (text items of _s) as text
  set AppleScript's text item delimiters to "\\"
  set _s to (text items of _s) as text
  set AppleScript's text item delimiters to astid
  return _s
end unescapeJSON