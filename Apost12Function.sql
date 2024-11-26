-- CREATE TABLE tb_cliente(
--     cod_cliente SERIAL PRIMARY KEY,
--     nome VARCHAR(200) NOT NULL
-- );
-- INSERT INTO tb_cliente (nome) VALUES ('João Santos'), ('Maria Andrade');
-- SELECT * FROM tb_cliente;
-- CREATE TABLE tb_tipo_conta(
--     cod_tipo_conta SERIAL PRIMARY KEY,
--     descricao VARCHAR(200) NOT NULL
-- );
-- INSERT INTO tb_tipo_conta (descricao) VALUES ('Conta Corrente'), ('Conta Poupança');
-- SELECT * FROM tb_tipo_conta;
-- CREATE TABLE tb_conta (
--     cod_conta SERIAL PRIMARY KEY,
--     status VARCHAR(200) NOT NULL DEFAULT 'aberta',
--     data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     data_ultima_transacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     saldo NUMERIC(10, 2) NOT NULL DEFAULT 1000 CHECK (saldo >= 1000),
--     cod_cliente INT NOT NULL,
--     cod_tipo_conta INT NOT NULL,
--     CONSTRAINT fk_cliente FOREIGN KEY (cod_cliente) REFERENCES
--     tb_cliente(cod_cliente),
--     CONSTRAINT fk_tipo_conta FOREIGN KEY (cod_tipo_conta) REFERENCES
--     tb_tipo_conta(cod_tipo_conta)
-- );
-- SELECT * FROM tb_conta;

-- DROP FUNCTION IF EXISTS fn_abrir_conta;
-- CREATE OR REPLACE FUNCTION fn_abrir_conta (IN p_cod_cli INT, IN p_saldo
-- NUMERIC(10, 2), IN p_cod_tipo_conta INT) RETURNS BOOLEAN
-- LANGUAGE plpgsql
-- AS $$
-- BEGIN
--     INSERT INTO tb_conta (cod_cliente, saldo, cod_tipo_conta) VALUES ($1, $2, $3);
--     RETURN TRUE;
-- EXCEPTION WHEN OTHERS THEN
--     RETURN FALSE;
-- END;
-- $$
-- DO $$
-- DECLARE
--     v_cod_cliente INT := 1;
--     v_saldo NUMERIC (10, 2) := 500;
--     v_cod_tipo_conta INT := 1;
--     v_resultado BOOLEAN;
-- BEGIN
--     SELECT fn_abrir_conta (v_cod_cliente, v_saldo, v_cod_tipo_conta) INTO
-- v_resultado;
--     RAISE NOTICE '%', format('Conta com saldo R$%s%s foi aberta', v_saldo, CASE
-- WHEN v_resultado THEN '' ELSE ' não' END);
--     v_saldo := 1000;
--     SELECT fn_abrir_conta (v_cod_cliente, v_saldo, v_cod_tipo_conta) INTO
-- v_resultado;
--     RAISE NOTICE '%', format('Conta com saldo R$%s%s foi aberta', v_saldo, CASE
-- WHEN v_resultado THEN '' ELSE ' não' END);
-- END;
-- $$

-- --routine se aplica a funções e procedimentos
-- DROP ROUTINE IF EXISTS fn_depositar;
-- CREATE OR REPLACE FUNCTION fn_depositar (IN p_cod_cliente INT, IN p_cod_conta INT,
-- IN p_valor NUMERIC(10, 2)) RETURNS NUMERIC(10, 2)
-- LANGUAGE plpgsql
-- AS $$
-- DECLARE
-- v_saldo_resultante NUMERIC(10, 2);
-- BEGIN
--     UPDATE tb_conta SET saldo = saldo + p_valor WHERE cod_cliente = p_cod_cliente
-- AND cod_conta = p_cod_conta;
--     SELECT saldo FROM tb_conta c WHERE c.cod_cliente = p_cod_cliente AND
-- c.cod_conta = p_cod_conta INTO v_saldo_resultante;
--     RETURN v_saldo_resultante;
-- END;
-- $$
-- DO $$
-- DECLARE
--     v_cod_cliente INT := 1;
--     v_cod_conta INT := 2;
--     v_valor NUMERIC(10, 2) := 200;
--     v_saldo_resultante NUMERIC (10, 2);
-- BEGIN
--     SELECT fn_depositar (v_cod_cliente, v_cod_conta, v_valor) INTO
-- v_saldo_resultante;
--     RAISE NOTICE '%', format('Após depositar R$%s, o saldo resultante é de R$%s',
-- v_valor, v_saldo_resultante);
-- END;
-- $$


 -- Ex. 1.1
CREATE TABLE contas (
    codigo_cliente INT,
    codigo_conta INT,
    saldo DECIMAL
);

 CREATE FUNCTION fn_consultar_saldo (codigo_cliente INT, codigo_conta INT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN 'Saldo conta';
END;
$$

SELECT fn_consultar_saldo(1, 123);

--1.2
CREATE OR REPLACE FUNCTION fn_transferir(
    p_cod_cliente_remetente INT,
    p_cod_conta_remetente INT,
    p_cod_cliente_destinatario INT,
    p_cod_conta_destinatario INT,
    p_valor NUMERIC(10, 2)
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    saldo_remetente NUMERIC(10, 2);
    saldo_destinatario NUMERIC(10, 2);
BEGIN
    -- Verifica saldo da conta remetente
    SELECT saldo INTO saldo_remetente
    FROM tb_conta
    WHERE cod_cliente = p_cod_cliente_remetente AND cod_conta = p_cod_conta_remetente;

    -- Verifica se saldo da conta remetente é suficiente
    IF saldo_remetente IS NULL OR saldo_remetente < p_valor THEN
        RAISE EXCEPTION 'Saldo insuficiente na conta remetente';
    END IF;

    -- Verifica saldo da conta destino
    SELECT saldo INTO saldo_destinatario
    FROM tb_conta
    WHERE cod_cliente = p_cod_cliente_destinatario AND cod_conta = p_cod_conta_destinatario;

    -- Verifica se conta destino existe
    IF saldo_destinatario IS NULL THEN
        RAISE EXCEPTION 'Conta destinatária não encontrada';
    END IF;

    -- Verifica se conta remetente e destino não ficarão negativas
    IF (saldo_destinatario + p_valor) < 0 THEN
        RAISE EXCEPTION 'A conta destinatária ficaria negativa';
    END IF;

    -- Realiza a transferência
    UPDATE tb_conta
    SET saldo = saldo - p_valor
    WHERE cod_cliente = p_cod_cliente_remetente AND cod_conta = p_cod_conta_remetente;

    UPDATE tb_conta
    SET saldo = saldo + p_valor
    WHERE cod_cliente = p_cod_cliente_destinatario AND cod_conta = p_cod_conta_destinatario;

    RETURN TRUE; -- Retorna verdadeiro se a transferência deu certo
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE; -- Retorna falso em caso de erro
END;
$$;

--1.3
-- testando função abrir conta
DO $$
DECLARE
    v_resultado BOOLEAN;
BEGIN

    v_resultado := fn_abrir_conta(1, 1000.00, 1); -- Cliente 1, saldo 1000, tipo de conta 1
    RAISE NOTICE 'Conta aberta com sucesso: %', v_resultado;
END;
$$;

-- testando função depositar
DO $$
DECLARE
    v_saldo_resultante NUMERIC(10, 2);
BEGIN

    v_saldo_resultante := fn_depositar(1, 1, 200.00); -- Cliente 1, conta 1, valor 200
    RAISE NOTICE 'Saldo após depósito: R$%.2f', v_saldo_resultante;
END;
$$;

-- testando função transferir
DO $$
DECLARE
    v_resultado BOOLEAN;
BEGIN

    v_resultado := fn_transferir(1, 1, 2, 2, 100.00); -- Cliente 1, conta 1 para Cliente 2, conta 2, valor 100
    RAISE NOTICE 'Transferência realizada com sucesso: %', v_resultado;
END;
$$;