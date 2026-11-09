-- =====================================================================
-- CÁLCULOS ESPECIALIZADOS: tabela para guardar as contas personalizadas
-- Execute no banco mydb (depois dos outros scripts).
-- =====================================================================
USE `mydb`;

CREATE TABLE IF NOT EXISTS `calculo_especializado` (
  `idcalculo` INT NOT NULL AUTO_INCREMENT,
  `organizador_id_organizador` INT NOT NULL,
  `evento_idevento` INT NULL,
  `nome` VARCHAR(120) NOT NULL,
  `descricao` VARCHAR(400) NULL,
  `formula` VARCHAR(500) NOT NULL,
  `variaveis` LONGTEXT NULL,
  `criado_em` DATETIME NOT NULL,
  `atualizado_em` DATETIME NOT NULL,
  PRIMARY KEY (`idcalculo`),
  INDEX `fk_calculo_organizador_idx` (`organizador_id_organizador` ASC),
  INDEX `fk_calculo_evento_idx` (`evento_idevento` ASC),
  CONSTRAINT `fk_calculo_organizador`
    FOREIGN KEY (`organizador_id_organizador`)
    REFERENCES `organizador` (`id_organizador`)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_calculo_evento`
    FOREIGN KEY (`evento_idevento`)
    REFERENCES `evento` (`idevento`)
    ON DELETE SET NULL
    ON UPDATE NO ACTION)
ENGINE = InnoDB;
