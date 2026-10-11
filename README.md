# atendimento-clinica

Reabilis — Secretária Virtual com IA para Clínica de Psicologia

Sistema de atendimento automatizado via WhatsApp para uma clínica de psicologia. Um agente de IA atende pacientes e terapeutas, marca, reagenda e cancela consultas, e dispara lembretes automáticos no dia anterior a cada sessão.

Nota: este repositório é uma versão sanitizada de um projeto real, publicada como peça de portfólio. Credenciais, tokens, nomes e dados de pacientes foram removidos e substituídos por placeholders. Nenhuma informação sensível ou identificável está incluída.

Funcionalidades
Atendimento por IA via WhatsApp, para pacientes e terapeutas
Agendamento, reagendamento e cancelamento de consultas em linguagem natural
Fluxo de aprovação: toda nova consulta fica pendente até o terapeuta confirmar pelo WhatsApp
Lembretes automáticos de consulta, uma vez ao dia
Protocolo de crise, com encaminhamento para CVV (188) e emergência (192)
Validação de assinatura de webhook (HMAC SHA-256) para bloquear requisições forjadas
Arquitetura
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
Stack
Camada	Tecnologia
Orquestração	n8n (Cloud)
IA conversacional	OpenAI (LLM, function/tool calling)
Canal de atendimento	WhatsApp Business API (Meta)
Banco de dados	Supabase (PostgreSQL)
Agenda	Google Calendar API
Workflows
1. Atendimento WhatsApp

Recebe mensagens via webhook, valida a assinatura da Meta e repassa para um agente de IA que:

identifica se quem está falando é paciente ou terapeuta;
consulta e atualiza o Supabase (pacientes, terapeutas, sessões);
cria, altera ou cancela eventos no Google Calendar do terapeuta correspondente;
reconhece sinais de crise e direciona para os canais de apoio corretos.

Toda nova consulta é criada com status pendente e só passa para agendado depois que o terapeuta responsável aprova pelo próprio WhatsApp.

2. Lembretes de Consulta

Workflow agendado (trigger diário às 8h) que busca no Supabase as consultas do dia seguinte com status agendado, envia um template de lembrete pré-aprovado pela Meta, e marca a consulta como lembrete enviado.

Modelo de dados

Ver supabase_schema.sql. Três tabelas principais: pacientes, terapeutas, sessoes — com sessoes.status controlando todo o ciclo de vida de uma consulta (pendente, agendado, confirmado, cancelado, reagendado, recusado).

Segurança
Validação HMAC SHA-256 (X-Hub-Signature-256) de toda requisição recebida no webhook, rejeitando qualquer chamada não assinada pela Meta
Limite de gasto (hard limit) configurado na conta da OpenAI
Rate limiting por contato, para evitar abuso/flood de mensagens
Configuração

Nenhuma credencial está incluída neste repositório. Ver .env.example para a lista de variáveis necessárias — preencha com suas próprias chaves ao reproduzir o projeto.

Status

🚧 Projeto em desenvolvimento ativo. Pendências atuais: aprovação de template de lembrete pela Meta, verificação de negócios no Business Manager, testes ponta a ponta antes de ativar em produção.

Autor

Erisson Meireles Mendes de Souza
