-- =====================================================================
-- NOVA VERSÃO: login seguro, bloqueio de tentativas e controle de sessão
-- Execute DEPOIS do script original (codigosqldotrabalhopi.sql).
-- Banco: mydb (ajuste o nome em USE se usar outro).
-- =====================================================================
USE `mydb`;

-- ---------------------------------------------------------------------
-- 0) Ajustes de dados existentes (evita falhas nas alterações abaixo)
-- ---------------------------------------------------------------------
UPDATE `convite` SET `status_confirmacao` = 'pendente' WHERE `status_confirmacao` IS NULL;

-- ---------------------------------------------------------------------
-- 1) ORGANIZADOR: senha (hash bcrypt), status ativo e email único
--    Organizadores já existentes ficam SEM senha até serem recadastrados
--    pelo utilitário bin/cadastrar_usuario.dart ou pela troca de senha.
-- ---------------------------------------------------------------------
ALTER TABLE `organizador`
  ADD COLUMN `senha_hash` VARCHAR(255) NULL AFTER `telefone`,
  ADD COLUMN `ativo` TINYINT(1) NOT NULL DEFAULT 1 AFTER `senha_hash`,
  ADD UNIQUE INDEX `uq_organizador_email` (`email` ASC);

-- ---------------------------------------------------------------------
-- 2) EVENTO: tipo do evento (Casamento, Aniversário etc.)
-- ---------------------------------------------------------------------
ALTER TABLE `evento`
  ADD COLUMN `tipo_evento` VARCHAR(100) NULL AFTER `DESCRICAO`;

-- ---------------------------------------------------------------------
-- 3) CONVIDADO: idade e assento (dados que o programa pede)
-- ---------------------------------------------------------------------
ALTER TABLE `convidado`
  ADD COLUMN `idade` INT NULL AFTER `telefone`,
  ADD COLUMN `assento` VARCHAR(10) NULL AFTER `idade`;

-- ---------------------------------------------------------------------
-- 4) MESA: uma mesa com o mesmo número não pode repetir no mesmo evento
-- ---------------------------------------------------------------------
ALTER TABLE `mesa`
  ADD UNIQUE INDEX `uq_mesa_evento_numero` (`evento_idevento` ASC, `numero_mesa` ASC);

-- ---------------------------------------------------------------------
-- 5) CONVITE: status obrigatório e uma pessoa só é convidada uma vez por evento
-- ---------------------------------------------------------------------
ALTER TABLE `convite`
  MODIFY `status_confirmacao` ENUM('pendente', 'confirmado', 'recusado')
    NOT NULL DEFAULT 'pendente',
  ADD UNIQUE INDEX `uq_convite_evento_convidado` (`evento_idevento` ASC, `convidado_idconvidado` ASC);

-- ---------------------------------------------------------------------
-- 6) CHECK-IN: um convite só pode fazer check-in uma vez
-- ---------------------------------------------------------------------
ALTER TABLE `checkin`
  ADD UNIQUE INDEX `uq_checkin_convite` (`convite_idconvite` ASC);

-- ---------------------------------------------------------------------
-- 7) NOVA TABELA: registro de TODAS as tentativas de login
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `login_registro` (
  `idlogin_registro` INT NOT NULL AUTO_INCREMENT,
  `email_informado` VARCHAR(100) NOT NULL,
  `sucesso` TINYINT(1) NOT NULL,
  `data_hora` DATETIME NOT NULL,
  `organizador_id_organizador` INT NULL,
  PRIMARY KEY (`idlogin_registro`),
  INDEX `fk_login_registro_organizador_idx` (`organizador_id_organizador` ASC),
  CONSTRAINT `fk_login_registro_organizador`
    FOREIGN KEY (`organizador_id_organizador`)
    REFERENCES `organizador` (`id_organizador`)
    ON DELETE SET NULL
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 8) NOVA TABELA: sessões (início e fim de cada login bem-sucedido)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `sessao_login` (
  `idsessao` INT NOT NULL AUTO_INCREMENT,
  `inicio` DATETIME NOT NULL,
  `fim` DATETIME NULL,
  `organizador_id_organizador` INT NOT NULL,
  PRIMARY KEY (`idsessao`),
  INDEX `fk_sessao_login_organizador_idx` (`organizador_id_organizador` ASC),
  CONSTRAINT `fk_sessao_login_organizador`
    FOREIGN KEY (`organizador_id_organizador`)
    REFERENCES `organizador` (`id_organizador`)
    ON DELETE CASCADE
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 9) NOVA TABELA: bloqueio temporário de login por email (1 linha por email)
--    Fica no banco, então o bloqueio vale mesmo se o programa for fechado.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `bloqueio_login` (
  `idbloqueio_login` INT NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(100) NOT NULL,
  `bloqueado_ate` DATETIME NOT NULL,
  PRIMARY KEY (`idbloqueio_login`),
  UNIQUE INDEX `uq_bloqueio_login_email` (`email` ASC))
ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- 10) NOVA TABELA: histórico de trocas de senha ("esqueci a senha")
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `troca_senha` (
  `idtroca_senha` INT NOT NULL AUTO_INCREMENT,
  `data_hora` DATETIME NOT NULL,
  `organizador_id_organizador` INT NOT NULL,
  PRIMARY KEY (`idtroca_senha`),
  INDEX `fk_troca_senha_organizador_idx` (`organizador_id_organizador` ASC),
  CONSTRAINT `fk_troca_senha_organizador`
    FOREIGN KEY (`organizador_id_organizador`)
    REFERENCES `organizador` (`id_organizador`)
    ON DELETE CASCADE
    ON UPDATE NO ACTION)
ENGINE = InnoDB;
