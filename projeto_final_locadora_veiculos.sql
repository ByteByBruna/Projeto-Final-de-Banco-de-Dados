-- ============================================================
-- PROJETO FINAL: SISTEMA DE GESTAO DE LOCADORA DE VEICULOS
-- Compatibilidade: MySQL 8.0+
-- Ambiente: MySQL Workbench
-- ============================================================

-- ATENCAO: descomente a linha abaixo somente se quiser apagar
-- e recriar um banco existente com o mesmo nome.
-- DROP DATABASE IF EXISTS locadora_veiculos;

-- ============================================================
-- BLOCO 1 - DDL (ESTRUTURA)
-- ============================================================

CREATE DATABASE IF NOT EXISTS locadora_veiculos
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE locadora_veiculos;

CREATE TABLE IF NOT EXISTS categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    cpf CHAR(11) NOT NULL UNIQUE,
    cnh VARCHAR(20) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    email VARCHAR(120) UNIQUE,
    data_cadastro DATE NOT NULL DEFAULT (CURRENT_DATE)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS veiculos (
    id_veiculo INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT NOT NULL,
    placa VARCHAR(8) NOT NULL UNIQUE,
    marca VARCHAR(50) NOT NULL,
    modelo VARCHAR(60) NOT NULL,
    ano_fabricacao YEAR NOT NULL,
    cor VARCHAR(30),
    valor_diaria DECIMAL(10,2) NOT NULL,
    status_veiculo ENUM('ATIVO','INATIVO') NOT NULL DEFAULT 'ATIVO',
    CONSTRAINT chk_veiculo_diaria CHECK (valor_diaria > 0),
    CONSTRAINT fk_veiculo_categoria FOREIGN KEY (id_categoria)
        REFERENCES categorias(id_categoria)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS locacoes (
    id_locacao INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_veiculo INT NOT NULL,
    data_retirada DATETIME NOT NULL,
    devolucao_prevista DATETIME NOT NULL,
    devolucao_real DATETIME NULL,
    valor_diaria_contratado DECIMAL(10,2) NOT NULL,
    status_locacao ENUM('RESERVADA','EM_ANDAMENTO','CONCLUIDA','CANCELADA')
        NOT NULL DEFAULT 'RESERVADA',
    observacoes VARCHAR(500),
    CONSTRAINT chk_locacao_periodo CHECK (devolucao_prevista > data_retirada),
    CONSTRAINT chk_locacao_diaria CHECK (valor_diaria_contratado > 0),
    CONSTRAINT chk_locacao_devolucao CHECK (
        devolucao_real IS NULL OR devolucao_real >= data_retirada
    ),
    CONSTRAINT fk_locacao_cliente FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_locacao_veiculo FOREIGN KEY (id_veiculo)
        REFERENCES veiculos(id_veiculo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_locacao_veiculo_periodo (id_veiculo, data_retirada, devolucao_prevista),
    INDEX idx_locacao_cliente (id_cliente),
    INDEX idx_locacao_status (status_locacao)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pagamentos (
    id_pagamento INT AUTO_INCREMENT PRIMARY KEY,
    id_locacao INT NOT NULL,
    data_pagamento DATETIME NULL,
    valor DECIMAL(10,2) NOT NULL,
    forma_pagamento ENUM('PIX','CREDITO','DEBITO','DINHEIRO','TRANSFERENCIA')
        NOT NULL,
    status_pagamento ENUM('PENDENTE','PAGO','ESTORNADO') NOT NULL DEFAULT 'PENDENTE',
    descricao VARCHAR(255),
    CONSTRAINT chk_pagamento_valor CHECK (valor > 0),
    CONSTRAINT fk_pagamento_locacao FOREIGN KEY (id_locacao)
        REFERENCES locacoes(id_locacao)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_pagamento_status_data (status_pagamento, data_pagamento)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS manutencoes (
    id_manutencao INT AUTO_INCREMENT PRIMARY KEY,
    id_veiculo INT NOT NULL,
    data_entrada DATE NOT NULL,
    data_saida DATE NULL,
    descricao VARCHAR(255) NOT NULL,
    custo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status_manutencao ENUM('ABERTA','EM_EXECUCAO','CONCLUIDA')
        NOT NULL DEFAULT 'ABERTA',
    CONSTRAINT chk_manutencao_custo CHECK (custo >= 0),
    CONSTRAINT chk_manutencao_datas CHECK (
        data_saida IS NULL OR data_saida >= data_entrada
    ),
    CONSTRAINT fk_manutencao_veiculo FOREIGN KEY (id_veiculo)
        REFERENCES veiculos(id_veiculo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_manutencao_veiculo_status (id_veiculo, status_manutencao)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS vistorias (
    id_vistoria INT AUTO_INCREMENT PRIMARY KEY,
    id_locacao INT NOT NULL,
    tipo_vistoria ENUM('RETIRADA','DEVOLUCAO') NOT NULL,
    data_vistoria DATETIME NOT NULL,
    quilometragem INT UNSIGNED NOT NULL,
    nivel_combustivel TINYINT UNSIGNED NOT NULL,
    observacoes VARCHAR(500),
    CONSTRAINT chk_vistoria_combustivel CHECK (nivel_combustivel BETWEEN 0 AND 100),
    CONSTRAINT fk_vistoria_locacao FOREIGN KEY (id_locacao)
        REFERENCES locacoes(id_locacao)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_vistoria_tipo UNIQUE (id_locacao, tipo_vistoria)
) ENGINE=InnoDB;

-- ============================================================
-- BLOCO 2 - DML (CARGA DE DADOS FICTICIOS)
-- IDs explicitos facilitam acompanhar os exemplos nas consultas.
-- ============================================================

INSERT INTO categorias (id_categoria, nome, descricao) VALUES
(1, 'Economico', 'Veiculos compactos para uso urbano'),
(2, 'Intermediario', 'Veiculos com mais espaco e conforto'),
(3, 'SUV', 'Veiculos utilitarios esportivos'),
(4, 'Executivo', 'Veiculos de categoria superior'),
(5, 'Utilitario', 'Veiculos para transporte de cargas');

INSERT INTO clientes
(id_cliente, nome, cpf, cnh, telefone, email, data_cadastro) VALUES
(1, 'Ana Beatriz Lima', '11111111101', 'CNH100001', '(61) 99911-1001', 'ana.lima@email.com', '2026-01-10'),
(2, 'Carlos Eduardo Souza', '11111111102', 'CNH100002', '(61) 99911-1002', 'carlos.souza@email.com', '2026-02-15'),
(3, 'Mariana Alves Rocha', '11111111103', 'CNH100003', '(61) 99911-1003', 'mariana.rocha@email.com', '2026-03-05'),
(4, 'Rafael Martins Costa', '11111111104', 'CNH100004', '(61) 99911-1004', 'rafael.costa@email.com', '2026-04-20'),
(5, 'Juliana Ferreira Melo', '11111111105', 'CNH100005', '(61) 99911-1005', 'juliana.melo@email.com', '2026-05-12'),
(6, 'Pedro Henrique Nunes', '11111111106', 'CNH100006', '(61) 99911-1006', 'pedro.nunes@email.com', '2026-06-08'),
(7, 'Camila Oliveira Reis', '11111111107', 'CNH100007', '(61) 99911-1007', 'camila.reis@email.com', '2026-07-18');

INSERT INTO veiculos
(id_veiculo, id_categoria, placa, marca, modelo, ano_fabricacao, cor, valor_diaria, status_veiculo) VALUES
(1, 1, 'ABC1D23', 'Chevrolet', 'Onix', 2023, 'Prata', 129.90, 'ATIVO'),
(2, 1, 'DEF4G56', 'Hyundai', 'HB20', 2024, 'Branco', 139.90, 'ATIVO'),
(3, 2, 'GHI7J89', 'Toyota', 'Corolla', 2023, 'Preto', 219.90, 'ATIVO'),
(4, 3, 'JKL1M23', 'Jeep', 'Compass', 2024, 'Cinza', 289.90, 'ATIVO'),
(5, 2, 'MNO4P56', 'Volkswagen', 'Virtus', 2022, 'Azul', 189.90, 'ATIVO'),
(6, 4, 'QRS7T89', 'BMW', '320i', 2023, 'Preto', 499.90, 'ATIVO'),
(7, 5, 'UVW1X23', 'Fiat', 'Fiorino', 2022, 'Branco', 199.90, 'ATIVO');

-- Periodos de exemplo; locacoes concluidas e futuras/em andamento
-- foram selecionadas para demonstrar diferentes consultas.
INSERT INTO locacoes
(id_locacao, id_cliente, id_veiculo, data_retirada, devolucao_prevista,
 devolucao_real, valor_diaria_contratado, status_locacao, observacoes) VALUES
(1, 1, 1, '2026-10-02 09:00:00', '2026-10-05 09:00:00', '2026-10-05 08:40:00', 129.90, 'CONCLUIDA', 'Locacao finalizada sem ocorrencias'),
(2, 2, 3, '2026-10-10 10:00:00', '2026-10-13 10:00:00', '2026-10-13 11:00:00', 219.90, 'CONCLUIDA', 'Devolucao registrada'),
(3, 3, 2, '2026-10-20 08:00:00', '2026-10-23 08:00:00', '2026-10-23 08:00:00', 139.90, 'CONCLUIDA', 'Locacao finalizada'),
(4, 1, 4, '2026-11-02 09:00:00', '2026-11-06 09:00:00', NULL, 289.90, 'EM_ANDAMENTO', 'Viagem em andamento'),
(5, 4, 5, '2026-11-08 09:00:00', '2026-11-11 09:00:00', NULL, 189.90, 'RESERVADA', 'Reserva futura'),
(6, 5, 1, '2026-11-12 10:00:00', '2026-11-15 10:00:00', NULL, 129.90, 'RESERVADA', 'Reserva futura'),
(7, 6, 6, '2026-09-05 09:00:00', '2026-09-07 09:00:00', '2026-09-07 09:00:00', 499.90, 'CONCLUIDA', 'Locacao executiva'),
(8, 7, 7, '2026-10-25 08:00:00', '2026-10-28 08:00:00', '2026-10-28 08:00:00', 199.90, 'CONCLUIDA', 'Locacao utilitaria');

INSERT INTO pagamentos
(id_pagamento, id_locacao, data_pagamento, valor, forma_pagamento, status_pagamento, descricao) VALUES
(1, 1, '2026-10-02 09:05:00', 389.70, 'PIX', 'PAGO', 'Pagamento da locacao 1'),
(2, 2, '2026-10-10 10:05:00', 659.70, 'CREDITO', 'PAGO', 'Pagamento da locacao 2'),
(3, 3, '2026-10-20 08:05:00', 419.70, 'DEBITO', 'PAGO', 'Pagamento da locacao 3'),
(4, 4, '2026-11-02 09:10:00', 500.00, 'PIX', 'PAGO', 'Entrada da locacao 4'),
(5, 4, NULL, 659.60, 'PIX', 'PENDENTE', 'Saldo previsto da locacao 4'),
(6, 5, NULL, 569.70, 'CREDITO', 'PENDENTE', 'Pagamento aguardando confirmacao'),
(7, 7, '2026-09-05 09:10:00', 999.80, 'TRANSFERENCIA', 'PAGO', 'Pagamento da locacao 7'),
(8, 8, '2026-10-25 08:10:00', 599.70, 'PIX', 'PAGO', 'Pagamento da locacao 8');

INSERT INTO manutencoes
(id_manutencao, id_veiculo, data_entrada, data_saida, descricao, custo, status_manutencao) VALUES
(1, 1, '2026-08-10', '2026-08-11', 'Troca de oleo e filtros', 380.00, 'CONCLUIDA'),
(2, 2, '2026-09-15', '2026-09-16', 'Revisao preventiva', 520.00, 'CONCLUIDA'),
(3, 3, '2026-10-01', '2026-10-02', 'Troca de pastilhas de freio', 740.00, 'CONCLUIDA'),
(4, 4, '2026-11-20', NULL, 'Avaliacao de suspensao', 350.00, 'EM_EXECUCAO'),
(5, 5, '2026-07-12', '2026-07-12', 'Alinhamento e balanceamento', 180.00, 'CONCLUIDA'),
(6, 6, '2026-06-02', '2026-06-04', 'Revisao geral', 1250.00, 'CONCLUIDA');

INSERT INTO vistorias
(id_vistoria, id_locacao, tipo_vistoria, data_vistoria, quilometragem, nivel_combustivel, observacoes) VALUES
(1, 1, 'RETIRADA', '2026-10-02 09:00:00', 25400, 100, 'Veiculo entregue limpo'),
(2, 1, 'DEVOLUCAO', '2026-10-05 08:40:00', 25720, 75, 'Sem danos aparentes'),
(3, 2, 'RETIRADA', '2026-10-10 10:00:00', 41300, 90, 'Pequeno risco preexistente anotado'),
(4, 2, 'DEVOLUCAO', '2026-10-13 11:00:00', 41880, 60, 'Risco conferido'),
(5, 3, 'RETIRADA', '2026-10-20 08:00:00', 18700, 100, 'Sem observacoes'),
(6, 3, 'DEVOLUCAO', '2026-10-23 08:00:00', 19020, 80, 'Sem danos aparentes'),
(7, 7, 'RETIRADA', '2026-09-05 09:00:00', 12000, 100, 'Veiculo conferido'),
(8, 7, 'DEVOLUCAO', '2026-09-07 09:00:00', 12350, 50, 'Devolucao regular');

-- ============================================================
-- BLOCO 3 - DQL (CONSULTAS E RELATORIOS)
-- ============================================================

-- CONSULTA 1: Historico de locacoes por cliente
SELECT
    l.id_locacao,
    c.nome AS cliente,
    v.marca,
    v.modelo,
    v.placa,
    l.data_retirada,
    l.devolucao_prevista,
    l.status_locacao
FROM locacoes l
INNER JOIN clientes c ON c.id_cliente = l.id_cliente
INNER JOIN veiculos v ON v.id_veiculo = l.id_veiculo
WHERE l.status_locacao <> 'CANCELADA'
ORDER BY l.data_retirada DESC;

-- CONSULTA 2: Veiculos sem locacao conflitante para o periodo informado.
-- Ajuste as datas do periodo conforme a demonstracao.
-- Esta consulta verifica locacoes nao canceladas e manutencoes nao concluidas.
SET @inicio_periodo = '2026-11-09 08:00:00';
SET @fim_periodo    = '2026-11-10 08:00:00';

SELECT v.id_veiculo, v.placa, v.marca, v.modelo, cat.nome AS categoria,
       v.valor_diaria
FROM veiculos v
INNER JOIN categorias cat ON cat.id_categoria = v.id_categoria
WHERE v.status_veiculo = 'ATIVO'
  AND NOT EXISTS (
      SELECT 1
      FROM locacoes l
      WHERE l.id_veiculo = v.id_veiculo
        AND l.status_locacao IN ('RESERVADA', 'EM_ANDAMENTO')
        AND l.data_retirada < @fim_periodo
        AND l.devolucao_prevista > @inicio_periodo
  )
  AND NOT EXISTS (
      SELECT 1
      FROM manutencoes m
      WHERE m.id_veiculo = v.id_veiculo
        AND m.status_manutencao IN ('ABERTA', 'EM_EXECUCAO')
        AND m.data_entrada < DATE(@fim_periodo)
        AND (m.data_saida IS NULL OR m.data_saida >= DATE(@inicio_periodo))
  )
ORDER BY v.valor_diaria, v.modelo;

-- CONSULTA 3: Total recebido por mes (considera somente pagamentos confirmados)
SELECT
    DATE_FORMAT(data_pagamento, '%Y-%m') AS mes,
    SUM(valor) AS total_recebido,
    COUNT(*) AS quantidade_pagamentos
FROM pagamentos
WHERE status_pagamento = 'PAGO'
  AND data_pagamento >= '2026-01-01'
  AND data_pagamento < '2027-01-01'
GROUP BY DATE_FORMAT(data_pagamento, '%Y-%m')
ORDER BY mes;

-- CONSULTA 4: Veiculos mais alugados
SELECT
    v.id_veiculo,
    v.marca,
    v.modelo,
    v.placa,
    COUNT(l.id_locacao) AS quantidade_locacoes
FROM veiculos v
LEFT JOIN locacoes l
    ON l.id_veiculo = v.id_veiculo
   AND l.status_locacao = 'CONCLUIDA'
WHERE v.status_veiculo = 'ATIVO'
GROUP BY v.id_veiculo, v.marca, v.modelo, v.placa
ORDER BY quantidade_locacoes DESC, v.modelo;

-- CONSULTA 5: Pagamentos pendentes
SELECT
    p.id_pagamento,
    l.id_locacao,
    c.nome AS cliente,
    v.modelo AS veiculo,
    p.valor,
    p.forma_pagamento,
    p.status_pagamento
FROM pagamentos p
INNER JOIN locacoes l ON l.id_locacao = p.id_locacao
INNER JOIN clientes c ON c.id_cliente = l.id_cliente
INNER JOIN veiculos v ON v.id_veiculo = l.id_veiculo
WHERE p.status_pagamento = 'PENDENTE'
ORDER BY l.data_retirada, c.nome;

-- CONSULTA 6: Custo total de manutencao por veiculo
SELECT
    v.id_veiculo,
    v.placa,
    v.marca,
    v.modelo,
    COUNT(m.id_manutencao) AS quantidade_manutencoes,
    COALESCE(SUM(m.custo), 0) AS custo_total_manutencao
FROM veiculos v
LEFT JOIN manutencoes m ON m.id_veiculo = v.id_veiculo
GROUP BY v.id_veiculo, v.placa, v.marca, v.modelo
ORDER BY custo_total_manutencao DESC, v.modelo;

-- CONSULTA EXTRA: Clientes com mais locacoes concluidas
SELECT
    c.id_cliente,
    c.nome,
    COUNT(l.id_locacao) AS locacoes_concluidas
FROM clientes c
INNER JOIN locacoes l ON l.id_cliente = c.id_cliente
WHERE l.status_locacao = 'CONCLUIDA'
GROUP BY c.id_cliente, c.nome
ORDER BY locacoes_concluidas DESC, c.nome;

-- ============================================================
-- FIM DO SCRIPT
-- Observacao: este projeto demonstra a estrutura e consultas.
-- Regras operacionais como bloqueio transacional de conflitos
-- de agenda exigem validacao adicional na aplicacao ou rotinas
-- de banco (por exemplo, transacoes/procedures/triggers).
-- ============================================================
