-- Atualiza SÓ a trigger da lista de espera para o modo "reserva".
-- Rode uma vez no notebook e uma vez no servidor, ANTES de usar o menu 11 da v3.4.
USE mydb;

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

SHOW TRIGGERS LIKE 'lista_espera';
