---
layout: post
title: "Genkit Go 1.0: Google's Framework for Building AI Applications in Go"
subtitle: "Unified API for multiple models, native RAG, type-safe flows, and a Developer UI"
author: otavio_celestino
date: 2026-08-31 08:00:00 -0300
categories: [Go, AI, Genkit]
tags: [go, golang, genkit, ai, llm, rag, google, gemini, agents]
comments: true
image: "/assets/img/posts/2026-09-02-genkit-go-framework-ia.png"
lang: en
original_post: "/genkit-go-framework-ia/"
---

Hey everyone!

Google released Genkit Go 1.0, the stable version of their open source framework for building generative AI applications in Go. After a period in alpha, 1.0 brings API stability with guaranteed compatibility within the 1.x series, a standalone CLI, and a Developer UI to test and monitor your flows.

In this post I'll cover what Genkit is, what problem it solves, how it works in practice, and what changed in 1.0.

---

## What is Genkit

Genkit is Google's open source framework for developing generative AI applications. The Go version combines static typing, native concurrency, and fast compilation with an abstraction layer over models, vector databases, and AI pipelines.

The core proposition is that you shouldn't have to rewrite the integration every time you switch models or providers. Genkit provides a unified interface that works with Gemini, GPT-4, Claude, local models via Ollama, and others, with minimal code changes.

---

## Unified generation API

One of the most common problems when building with LLMs is that each provider has its own SDK, its own request and response formats, and its own conventions. Switching models means rewriting the integration.

Genkit solves this with a consistent interface. To switch between models, you change the name:

```go
// Gemini
response, err := ai.Generate(ctx, googleai.Model("gemini-2.5-flash"), ...)

// GPT-4o
response, err := ai.Generate(ctx, openai.Model("gpt-4o"), ...)

// Claude
response, err := ai.Generate(ctx, anthropic.Model("claude-sonnet-5"), ...)
```

Same call, same response format, regardless of provider. This has real practical value in projects where you want to experiment with different models or maintain fallbacks.

---

## Type-safe flows

The central concept in Genkit is **flows** — multi-step workflows with built-in typing and observability. You define a flow with Go structs and the framework automatically validates inputs and outputs via JSON schema.

```go
type RecipeInput struct {
    Ingredients []string `json:"ingredients"`
    Servings    int      `json:"servings"`
}

type Recipe struct {
    Name         string   `json:"name"`
    Instructions []string `json:"instructions"`
    PrepTime     string   `json:"prep_time"`
}

recipeFlow := genkit.DefineFlow("generateRecipe",
    func(ctx context.Context, input RecipeInput) (Recipe, error) {
        response, err := ai.GenerateData[Recipe](ctx,
            googleai.Model("gemini-2.5-flash"),
            ai.WithTextPrompt(fmt.Sprintf(
                "Create a recipe using %v for %d people",
                input.Ingredients, input.Servings,
            )),
        )
        if err != nil {
            return Recipe{}, err
        }
        return response.Output(), nil
    },
)
```

The flow is type-safe end to end. The model receives the prompt, returns JSON, Genkit validates against the `Recipe` struct schema, and you get a typed Go value back. No manual parsing, no `map[string]interface{}`.

---

## Tool calling

Beyond generating text and structured data, Genkit supports tool calling — you define Go functions and the model decides when and how to call them.

```go
getWeather := ai.DefineTool(
    "getWeather",
    "Returns the current temperature for a city",
    func(ctx context.Context, input struct {
        City string `json:"city"`
    }) (string, error) {
        // real call to a weather API
        return fetchWeather(input.City)
    },
)

response, err := ai.Generate(ctx,
    googleai.Model("gemini-2.5-flash"),
    ai.WithTextPrompt("What's the weather in São Paulo right now?"),
    ai.WithTools(getWeather),
)
```

The model receives the tool definition, decides to call `getWeather` with `{"city": "São Paulo"}`, receives the result, and incorporates it into the final response. You don't need to manage that loop manually. Genkit handles the orchestration.

---

## Native RAG

Retrieval-Augmented Generation is a common pattern for connecting LLMs to your own data. Genkit has native RAG support with simple APIs for indexing and retrieving documents, with support for multiple vector database providers (Pinecone, among others).

```go
// index documents
err := ai.Index(ctx, indexer, ai.WithDocs(documents...))

// retrieve relevant documents and use in prompt
docs, err := ai.Retrieve(ctx, retriever,
    ai.WithRetrieverText("how does the payment system work?"),
)

response, err := ai.Generate(ctx, model,
    ai.WithTextPrompt("Answer based on the provided documents"),
    ai.WithDocs(docs...),
)
```

Switching vector databases works the same as switching models: you change the `indexer` and `retriever` without touching the rest of the code.

---

## Dotprompt: prompts as versionable files

A practical problem in LLM projects is that prompts end up scattered through the code as string literals, without proper versioning and without a clear separation between logic and instruction.

Genkit has **Dotprompt** — `.prompt` files that consolidate in one place the prompt text, input and output schemas, model selection, and generation settings:

```
---
model: googleai/gemini-2.5-flash
input:
  schema:
    topic: string
    audience: string
output:
  schema:
    title: string
    sections: string[]
    conclusion: string
---

You are an experienced technical writer.
Write an article about {{topic}} for an audience of {{audience}}.
```

The file lives in the repository alongside the code, is versionable with Git, and can be edited without recompiling the application. Prompts stop being strings buried inside functions.

---

## Deployment as HTTP endpoints

A Genkit flow is automatically an HTTP endpoint. To expose the flow as an API:

```go
mux := http.NewServeMux()
mux.Handle("/recipe", genkit.Handler(recipeFlow))

server := &http.Server{
    Addr:    ":8080",
    Handler: mux,
}
server.Start(ctx)
```

With no additional configuration, the flow receives POST requests with the JSON input and returns the typed output. This makes it straightforward to integrate with other services and deploy on any infrastructure that runs Go containers.

---

## What changed in 1.0

The main change from alpha to 1.0 is **API stability**. Genkit follows the same commitment as Go itself: within the 1.x series, there will be no breaking changes.

Beyond that, 1.0 brings:

**Standalone CLI** — installation with no additional dependencies:

```bash
curl -sL cli.genkit.dev | bash
```

**Developer UI** — a visual interface to test flows, inspect execution step by step, monitor latency and token consumption, and explore traces. Useful during development to understand what the model is doing at each step of the flow.

**`genkit init:ai-tools`** — a new command that configures AI assistants (Gemini CLI, Claude Code, Cursor) with documentation and MCP tools integrated into the project, so AI agents themselves can work with Genkit in your codebase.

---

## Available plugins

In 1.0, Genkit Go supports:

- **Google AI** (Gemini 2.5 Flash, Gemini 2.5 Pro, etc.)
- **Vertex AI** (Google Cloud models)
- **OpenAI** (GPT-4o, GPT-4 Turbo, etc.)
- **Anthropic** (Claude Sonnet, Claude Haiku, etc.)
- **Ollama** (local open source models — Llama, Mistral, Qwen, etc.)
- **Pinecone** (vector database for RAG)
- **Google Cloud** (telemetry and observability)

---

## Is it worth using?

Genkit fills a space that was being occupied by Go ports of Python frameworks like LangChain Go and LlamaIndex Go, with the difference of being developed by Google with Go as a first-class language.

The strengths are the unified model API (which reduces provider lock-in), type-safe flows (which use the Go compiler as a validation layer), and built-in observability, which is what's most often missing in LLM projects going to production.

The caveat is that the ecosystem is still growing — the plugins cover the main providers, but integrations with more specific vector databases and with observability tools beyond Google Cloud are still limited.

For new projects that need to integrate LLMs in Go, it's worth experimenting with. For existing projects with direct integrations, the decision depends on how much you stand to gain from the abstraction versus the migration cost.

---

Have you used Genkit or a similar framework in Go? Tell me in the comments.

See you in the next post!

**References:**
- [Introducing Genkit for Go — Google Developers Blog](https://developers.googleblog.com/introducing-genkit-for-go-build-scalable-ai-powered-apps-in-go/)
- [Announcing Genkit Go 1.0 — Google Developers Blog](https://developers.googleblog.com/announcing-genkit-go-10-and-enhanced-ai-assisted-development/)
