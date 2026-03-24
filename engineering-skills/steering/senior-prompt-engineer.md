---
inclusion: fileMatch
fileMatchPattern: ["**/*.prompt", "**/*.txt", "**/prompts/**", "**/agents/**", "**/rag/**", "**/llm/**"]
---

# Senior Prompt Engineer

Guidance for prompt design, LLM integration, RAG systems, and agentic architectures.

---

## Prompt Design Principles

- Specify output format explicitly — never leave it implicit
- Use numbered instructions over prose paragraphs
- Replace vague verbs: `"analyze"` → `"list the top 3 issues with severity ratings"`
- Add 2–3 few-shot examples when output format is non-trivial
- Remove redundant context; every token should earn its place
- Separate system instructions, context, and user input into distinct sections

### System Prompt Structure

```
You are a [role] that [primary capability].

## Context
[Relevant background — only what the model needs]

## Instructions
1. [One action per step]
2. [Numbered, unambiguous]

## Output Format
[Exact schema, template, or example]

## Examples
Input: [example]
Output: [example]
```

---

## Core Prompt Patterns

### Few-Shot Classification

```python
PROMPT = """Classify the sentiment as positive, negative, or neutral.

Examples:
Review: "Arrived quickly and works perfectly!"
Sentiment: positive

Review: "Completely broken, waste of money."
Sentiment: negative

Review: "It's okay, does what it says."
Sentiment: neutral

Review: "{review}"
Sentiment:"""
```

### Chain of Thought

```python
PROMPT = """Solve this step by step.

Problem: {problem}

Steps:
1. Identify what is known
2. Determine what is needed
3. Apply the relevant approach
4. Verify the result

Answer:"""
```

### Structured Output (JSON)

```python
PROMPT = """Extract information from the text and return valid JSON only.

Schema:
{
  "name": "string",
  "date": "ISO 8601 or null",
  "amount": "number or null",
  "currency": "3-letter code or null"
}

Text: {text}

JSON:"""
```

---

## RAG Implementation

```python
from openai import OpenAI
import chromadb

client = OpenAI()
collection = chromadb.Client().get_or_create_collection("docs")

def rag_query(question: str, n_results: int = 5) -> str:
    results = collection.query(query_texts=[question], n_results=n_results)
    context = "\n\n".join(results["documents"][0])
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "Answer using only the provided context. If the context is insufficient, say so."},
            {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {question}"}
        ]
    )
    return response.choices[0].message.content
```

**RAG quality targets:**
- Context Relevance > 0.80
- Answer Faithfulness > 0.90
- Retrieval Precision@5 > 0.75

---

## LLM Integration Patterns

### Retry with Exponential Backoff

```python
import time
from openai import OpenAI, RateLimitError

def call_with_retry(prompt: str, max_retries: int = 3) -> str:
    client = OpenAI()
    for attempt in range(max_retries):
        try:
            return client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": prompt}]
            ).choices[0].message.content
        except RateLimitError:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)
```

### Provider Abstraction

```typescript
interface LLMProvider {
  complete(prompt: string, options?: CompletionOptions): Promise<string>;
}

class OpenAIProvider implements LLMProvider {
  async complete(prompt: string) { /* ... */ }
}

class AnthropicProvider implements LLMProvider {
  async complete(prompt: string) { /* ... */ }
}
```

Always program to the `LLMProvider` interface — never couple application logic to a specific SDK.

---

## Agent Architecture (ReAct Pattern)

```python
AGENT_PROMPT = """You have access to these tools: {tools}

Use this format:
Thought: [reasoning]
Action: [tool_name]
Action Input: [input]
Observation: [result]
... (repeat as needed)
Thought: I have enough information.
Final Answer: [answer]

Question: {question}"""
```

- Keep tool descriptions concise and unambiguous
- Validate tool inputs before execution
- Set a maximum iteration limit to prevent infinite loops
- Log Thought/Action/Observation traces for debugging

---

## Token Cost Reference

| Model | Input / 1M tokens | Output / 1M tokens |
|---|---|---|
| GPT-4o | $2.50 | $10.00 |
| GPT-4o-mini | $0.15 | $0.60 |
| Claude 3.5 Sonnet | $3.00 | $15.00 |
| Claude 3 Haiku | $0.25 | $1.25 |

Use `gpt-4o-mini` or `Claude 3 Haiku` for high-volume, low-complexity tasks. Reserve frontier models for reasoning-heavy or high-stakes outputs.

---

## Common Pitfalls

| Issue | Fix |
|---|---|
| Hallucinated structured output | Use JSON mode or constrained decoding |
| Inconsistent few-shot format | Ensure all examples follow identical formatting |
| Context window overflow | Chunk documents; summarize or truncate older turns |
| Prompt injection in user input | Sanitize inputs; isolate user content from instructions |
| Non-deterministic outputs | Set `temperature: 0` for classification/extraction tasks |
| Silent failures in agents | Always validate tool outputs before passing to next step |
