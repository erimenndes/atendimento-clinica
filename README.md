# Reabilis — Secretária Virtual com IA para Clínica de Psicologia

Sistema de atendimento automatizado via WhatsApp para uma clínica de psicologia. Um agente de IA atende pacientes e terapeutas, marca, reagenda e cancela consultas, e dispara lembretes automáticos no dia anterior a cada sessão.

> **Nota:** este repositório é uma versão sanitizada de um projeto real, publicada como peça de portfólio. Credenciais, tokens, nomes e dados de pacientes foram removidos e substituídos por placeholders. Nenhuma informação sensível ou identificável está incluída.

## Funcionalidades

- Atendimento por IA via WhatsApp, para pacientes e terapeutas
- Agendamento, reagendamento e cancelamento de consultas em linguagem natural
- Fluxo de aprovação: toda nova consulta fica pendente até o terapeuta confirmar pelo WhatsApp
- Lembretes automáticos de consulta, uma vez ao dia
- Protocolo de crise, com encaminhamento para CVV (188) e emergência (192)

## Arquitetura

```
WhatsApp Business API (Meta)
            │
            ▼
      Webhook + validação de assinatura
            │
            ▼
           n8n  (orquestração)
      ┌─────┴─────────────┐
      │                    │
Agente de IA         Workflow de Lembretes
(OpenAI, function     (trigger diário, 8h)
 calling)                   │
      │                    │
      ▼                    ▼
   Supabase (dados)  ──  Google Calendar
   pacientes /            (1 calendário
   terapeutas /            por terapeuta)
   sessões
```

### Stack

| Camada | Tecnologia |
|---|---|
| Orquestração | n8n (Cloud) |
| IA conversacional | OpenAI (LLM, function/tool calling) |
| Canal de atendimento | WhatsApp Business API (Meta) |
| Banco de dados | Supabase (PostgreSQL) |
| Agenda | Google Calendar API |

## Workflows

### 1. Atendimento WhatsApp

Recebe mensagens via webhook, valida a assinatura da Meta e repassa para um agente de IA que:

- identifica se quem está falando é paciente ou terapeuta;
- consulta e atualiza o Supabase (pacientes, terapeutas, sessões);
- cria, altera ou cancela eventos no Google Calendar do terapeuta correspondente;
- reconhece sinais de crise e direciona para os canais de apoio corretos.

Toda nova consulta é criada com status `pendente` e só passa para `agendado` depois que o terapeuta responsável aprova pelo próprio WhatsApp.

### 2. Lembretes de Consulta

Workflow agendado (trigger diário às 8h) que busca no Supabase as consultas do dia seguinte com status `agendado`, envia um template de lembrete pré-aprovado pela Meta, e marca a consulta como lembrete enviado.

## Estrutura do repositório

```
├── README.md
├── supabase_schema.sql          # tabelas do banco
├── .env.example                 # credenciais necessárias (sem valores)
└── workflows/
    ├── atendimento-whatsapp.json   # agente de IA + ferramentas (Supabase, Calendar, WhatsApp)
    └── lembretes-consulta.json     # lembretes diários via template
```

### Como reproduzir

1. Crie as tabelas rodando `supabase_schema.sql` no SQL Editor do Supabase.
2. No n8n, importe os dois arquivos de `workflows/` (menu ⋮ → *Import from file*).
3. Conecte suas próprias credenciais nos nós sinalizados (WhatsApp Business Cloud, Google Calendar, OpenAI, Supabase) e preencha os campos marcados como `<__PLACEHOLDER_VALUE__...>`.
4. Preencha as informações da clínica no *System Message* do agente.
5. Teste o fluxo completo (paciente agenda → terapeuta aprova → lembrete) antes de ativar.

## Modelo de dados

Ver [`supabase_schema.sql`](./supabase_schema.sql). Três tabelas principais: `pacientes`, `terapeutas`, `sessoes` — com `sessoes.status` controlando todo o ciclo de vida de uma consulta (`pendente`, `agendado`, `confirmado`, `cancelado`, `reagendado`, `recusado`).

## Segurança e privacidade

**Já aplicado**
- Aprovação humana: nenhuma consulta é confirmada ao paciente sem o terapeuta aprovar
- Protocolo de crise no prompt do agente, sem tentativa de atendimento clínico pela IA
- Nenhuma credencial nem dado de paciente neste repositório

**Planejado / em andamento**
- Validação da assinatura de webhook da Meta (`X-Hub-Signature-256`) usando o App Secret na credencial do trigger
- Hard limit de gasto na conta da OpenAI e rate limiting por contato
- Identificação do remetente de forma determinística (número vindo do webhook, e não informado pelo modelo às ferramentas), para que ninguém consiga se passar por terapeuta ou consultar dados de outro paciente
- Restringir o destino de mensagens enviadas pelo agente
- LGPD: relatórios e dados de pacientes acessíveis apenas ao profissional responsável

## Configuração

Nenhuma credencial está incluída neste repositório. Ver [`.env.example`](./.env.example) para a lista de variáveis necessárias — preencha com suas próprias chaves ao reproduzir o projeto.

## Status

🚧 Projeto em desenvolvimento. Pendências conhecidas:

- Aprovação do template de lembrete na Meta e verificação do negócio no Business Manager
- No workflow de lembretes, ajustar tabela/colunas do Supabase e buscar nome e telefone do paciente (tabela `pacientes`) a partir de `sessoes.paciente_id`
- Definir prazos de expiração para aprovação do terapeuta e confirmação do paciente
- Testes ponta a ponta antes de ativar em produção

## Autor

Erisson Meireles Mendes de Souza
