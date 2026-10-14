# Tagara: brand guidelines v0.3

> Última atualização: 2026-10-14
> Status: v0.3, aplicado no app

## Referência rápida

| Elemento | Valor |
|---|---|
| Nome | Tagara (de "tagarela") |
| Cores | Grafite `#2F332C` e violeta `#5B2A86`, sobre os fundos do sistema |
| Personalidade | Amigo esperto: casual, confiante, humor leve e pontual |
| Fonte | SF Pro no app; Atkinson Hyperlegible Next na marca fora do app |
| Ícone | Três barras de vidro, a do meio em violeta, sobre grafite que afunda em violeta |

---

## 1. Voz

O Tagara é um **amigo esperto**: fala como gente, é confiante e tem humor leve. O humor aparece nos textos curtos da interface, nunca no meio do caminho do usuário.

| Formal ○ ○ ● ○ ○ Casual | Sério ○ ○ ● ○ ○ Brincalhão | Contido ○ ● ○ ○ ○ Expressivo |
|---|---|---|

| Situação | Exemplo |
|---|---|
| Título do site | Fala que eu escrevo. |
| Gravando | ouvindo… |
| Histórico vazio | Nada por aqui ainda. Segura ⌥ e manda ver. |
| Sem microfone | Não tô te ouvindo. Libera o microfone? |

---

## 2. Cor

A marca é o **grafite** e o **violeta** do ícone. No app, eles ficam sobre os fundos do próprio macOS (claro e escuro do sistema). O papel verde da primeira versão foi descartado: não casou com a interface.

| Token | Claro | Escuro | Uso |
|---|---|---|---|
| `violeta` (AccentColor do app) | `#5B2A86` | `#8E5CC9` | seleção, botões, toggles, destaques |
| `violeta-claro` | `#C7A2EC` | `#C7A2EC` | detalhe sobre fundo grafite (pílula, ícone) |
| `grafite` | `#2F332C` | `#2F332C` | fundo do ícone e da pílula de gravação |
| `sobre-grafite` | `#F1F4EC` | `#F1F4EC` | texto e barras sobre grafite |
| Fundos, texto e separadores | sistema | sistema | fundos da janela, `.secondary`, `.separator`, `.quinary` |

### Contraste (WCAG)

| Par | Razão |
|---|---|
| violeta (claro) sobre branco | 9,9 : 1 |
| texto branco sobre violeta (claro) | 9,9 : 1 |
| texto branco sobre violeta (escuro) | 4,6 : 1 |
| violeta (escuro) sobre o fundo escuro do sistema | 3,6 : 1 (elementos de interface) |

---

## 3. Tipografia

- **App:** SF Pro, a fonte do sistema, em todos os textos. É o que faz o app soar nativo.
- **Marca fora do app** (site, materiais): Atkinson Hyperlegible Next, com a Mono para trechos de transcrição. Arquivos e licença OFL em `branding/fonts/`.

---

## 4. Ícone

- **Conceito:** a menor onda de voz possível, três barras, com a do meio em violeta.
- **Fundo:** grafite que afunda em violeta na parte de baixo.
- **Material:** Liquid Glass do macOS 26, montado no Icon Composer. O app usa `Resources/AppIcon.icon`, compilado pelo `actool` no build.
- **Modos:** claro e escuro desenhados; o colorido (tingido) fica no padrão gerado pelo sistema.
- **Fonte de verdade:** `branding/icons/refine.py` (variação `tb-e-fundo`).

---

## 5. Barra de menu e pílula

As três barras do ícone são a marca em movimento:

| Estado | Barra de menu (template, monocromático) | Pílula de gravação |
|---|---|---|
| Parado | três barras na proporção do ícone (0,48 · 1 · 0,48) | escondida |
| Faltando configurar | as mesmas barras, apagadas | escondida |
| Gravando | as barras seguem o volume da sua voz | barras ao vivo (a do meio em violeta) e "ouvindo…" |
| Mãos livres (toque duplo) | as barras seguem a voz | barras ao vivo e "ouvindo… toque ⌥ para terminar" |
| Escrevendo | três barras baixas e iguais | barras "respirando" em sequência e "escrevendo…" |
| Aviso | barras apagadas | ícone de aviso em violeta claro e o texto na voz da marca |

A pílula é sempre escura (`grafite` `#2F332C`), como os HUDs do macOS. Minimalista de propósito: sem brilho, eco ou pulsação.

## 6. Janela do app

Nativa do macOS: `NavigationSplitView` com barra lateral (Início, Histórico, Ajustes), fundos do sistema e o violeta como AccentColor.

- **Início:** saudação com a tecla, números do dia e do total, gráfico dos últimos 14 dias, último ditado com "Copiar" e campo para testar.
- **Histórico:** aba própria, com busca, agrupado por dia (Hoje, Ontem, data), copiar e apagar no hover ou no menu de contexto.
- **Ajustes:** `Form` agrupado (Geral, Ditado, Privacidade, Permissões).

## 7. Design tokens

- `assets/design-tokens.json` e `assets/design-tokens.css` (variáveis `--tg-*`, com modo escuro).
- No app: `Sources/Tagara/Brand.swift`.

## Histórico

- v0.1 (2026-10-14): nome, voz, cor, tipografia e ícone.
- v0.2 (2026-10-14): barra de menu, pílula, janela e design tokens aplicados no app.
- v0.3 (2026-10-14): janela refeita do zero, nativa, com barra lateral; papel verde descartado; app usa SF Pro e AccentColor violeta.
