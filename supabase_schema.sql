-- Reabilis — Schema do banco de dados (Supabase / PostgreSQL)
-- Versão sanitizada — sem dados reais, apenas estrutura.

create extension if not exists "pgcrypto";

-- Terapeutas da clínica
create table terapeutas (
    id uuid primary key default gen_random_uuid(),
    nome text not null,
    telefone text not null unique,
    google_calendar_id text,          -- calendário do Google dedicado a este terapeuta
    ativo boolean not null default true,
    created_at timestamptz not null default now()
);

-- Pacientes atendidos
create table pacientes (
    id uuid primary key default gen_random_uuid(),
    nome text not null,
    telefone text not null unique,
    data_nascimento date,
    terapeuta_id uuid references terapeutas(id),
    status text not null default 'ativo',
    observacoes text,
    created_at timestamptz not null default now()
);

-- Sessões / consultas agendadas
create table sessoes (
    id uuid primary key default gen_random_uuid(),
    paciente_id uuid not null references pacientes(id),
    terapeuta_id uuid not null references terapeutas(id),
    data_hora timestamptz not null,
    status text not null default 'pendente'
        check (status in ('pendente', 'agendado', 'confirmado', 'cancelado', 'reagendado', 'recusado')),
    valor numeric(10, 2),
    google_event_id text,             -- id do evento correspondente no Google Calendar
    observacoes text,                 -- notas de sessão (usadas no relatório de evolução assistido por IA)
    created_at timestamptz not null default now()
);

create index idx_sessoes_data_hora on sessoes (data_hora);
create index idx_sessoes_status on sessoes (status);
create index idx_pacientes_terapeuta on pacientes (terapeuta_id);
