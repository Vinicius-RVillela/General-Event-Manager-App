-- =====================================================================
-- LISTA DE ESPERA: limite de vagas, vagas em tempo real e histórico
-- Rodar como root no notebook E no servidor. O código do app não muda.
-- =====================================================================
USE mydb;

-- 1) LIMITE DE VAGAS DO EVENTO (pode mudar a qualquer hora; NULL = sem limite)
ALTER TABLE evento
  ADD COLUMN IF NOT EXISTS limite_convidados INT NULL
  COMMENT 'Máximo de convites ativos. NULL = sem limite. Pode ser alterado.';

-- 2) VIEW: vagas calculadas na hora (JOIN de evento com convite)
CREATE OR REPLACE VIEW vagas_evento AS
SELECT
  e.idevento,
  e.nome,
  e.limite_convidados,
  COUNT(c.idconvite)                       AS convites_ativos,
  e.limite_convidados - COUNT(c.idconvite) AS vagas_livres,
  (SELECT COUNT(*) FROM lista_espera le
    WHERE le.evento_idevento = e.idevento) AS pessoas_na_fila
FROM evento e
LEFT JOIN convite c
       ON c.evento_idevento = e.idevento
      AND c.status_confirmacao <> 'recusado'
GROUP BY e.idevento, e.nome, e.limite_convidados;

-- 3) HISTÓRICO: quem saiu da fila, quando e por quê
CREATE TABLE IF NOT EXISTS historico_lista_espera (
  idhistorico_lista_espera INT AUTO_INCREMENT PRIMARY KEY,
  evento_idevento          INT NOT NULL,
  convidado_idconvidado    INT NOT NULL,
  posicao                  INT,
  entrou_em                DATETIME,
  saiu_em                  DATETIME NOT NULL,
  motivo                   ENUM('promovido','removido') NOT NULL
);

-- 4) TRIGGER DE RESERVA: antes de apagar alguém da fila, anota no histórico,
--    MAS só se o programa não fez isso sozinho.
--    O app de terminal (v3.4) grava o histórico no código e, ao conectar, roda
--    SET @historico_pelo_codigo = 1  -> nessa conexão a trigger não faz nada.
--    O app com API não marca essa variável -> a trigger grava por ele.
DROP TRIGGER IF EXISTS tg_saiu_da_fila;
CREATE TRIGGER tg_saiu_da_fila
BEFORE DELETE ON lista_espera
FOR EACH ROW
INSERT INTO historico_lista_espera
  (evento_idevento, convidado_idconvidado, posicao, entrou_em, saiu_em, motivo)
SELECT OLD.evento_idevento, OLD.convidado_idconvidado, OLD.posicao, OLD.criado_em, NOW(),
   IF(EXISTS(SELECT 1 FROM convite
              WHERE evento_idevento       = OLD.evento_idevento
                AND convidado_idconvidado = OLD.convidado_idconvidado),
      'promovido', 'removido')
FROM DUAL
WHERE @historico_pelo_codigo IS NULL;

-- 5) TRAVA: mesma pessoa não pode estar duas vezes na fila do mesmo evento
--    (se houver repetidos, a linha abaixo aparece e o ALTER dá erro)
SELECT 'REPETIDOS NA FILA (deve vir vazio):' AS aviso;
SELECT evento_idevento, convidado_idconvidado, COUNT(*) AS vezes
FROM lista_espera
GROUP BY evento_idevento, convidado_idconvidado
HAVING COUNT(*) > 1;

ALTER TABLE lista_espera
  ADD UNIQUE INDEX IF NOT EXISTS uq_espera_evento_convidado
  (evento_idevento, convidado_idconvidado);

-- 6) CONFERÊNCIA
SELECT * FROM vagas_evento;
SHOW TRIGGERS LIKE 'lista_espera';
