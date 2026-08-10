# Desafio HunCoding × JetBrains

A JetBrains topou uma parceria e temos **10 licenças anuais** para distribuir.
A missão: escreva um post sobre Go ou sobre como você usa Golang em algum projeto,
abra um PR aqui e concorra.

## Regras

- O post deve ser sobre **Go / Golang** — linguagem, ferramentas, projetos, experiências reais.
- Conteúdo original, de sua autoria. Sem repost de outros sites.
- Prazo: **1 semana** a partir da data de publicação do vídeo de anúncio.
- Os **10 melhores posts** ganham uma licença JetBrains All Products Pack por 1 ano.
- A avaliação é feita pelo Otavio e leva em conta critérios como clareza, profundidade,
  originalidade e relevância — não há fórmula exata, é uma análise qualitativa.

## Como participar

1. Faça um **fork** deste repositório.
2. Crie um branch no seu fork: `post/seu-slug-aqui`.
3. Adicione seu post em `_posts/{data}-{slug}/` seguindo a estrutura abaixo.
4. Abra um **Pull Request** para `main` com o template preenchido.
5. Aguarde a revisão — pode haver pedidos de ajuste antes da aprovação.

Não é necessário ter conta em nenhuma plataforma além do GitHub.

## Estrutura do post

```
_posts/
└── 2026-08-10-meu-slug/
    └── 2026-08-10-meu-slug.md
```

### Frontmatter obrigatório

```yaml
---
layout: post
title: "Título do Post"
author: seu_usuario_github
date: 2026-08-10 08:00:00 -0300
categories: [Go]
tags: [go, golang]
comments: true
lang: pt-BR
---
```

- `author` pode ser qualquer identificador — coloque seu usuário do GitHub.
- `lang` aceita `pt-BR` ou `en`.
- Posts em inglês devem ter `original_post: "/seu-slug/"` apontando para a versão PT-BR (se houver).
- Imagens vão em `assets/img/posts/` e são opcionais.

## Dúvidas

Abra uma [Issue](../../issues) ou deixe um comentário no vídeo de anúncio.
