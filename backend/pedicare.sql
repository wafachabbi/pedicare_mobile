-- =============================================================
--  PediCare AI — Script SQL MySQL (XAMPP)
--  Importer via phpMyAdmin ou : mysql -u root < pedicare.sql
-- =============================================================

CREATE DATABASE IF NOT EXISTS pedicare CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE pedicare;

-- ── Utilisateurs (parents & pédiatres) ──────────────────────
CREATE TABLE IF NOT EXISTS users (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100)  NOT NULL,
  email       VARCHAR(150)  NOT NULL UNIQUE,
  password    VARCHAR(255)  NOT NULL,  -- bcrypt hash
  role        ENUM('parent','pediatre') NOT NULL DEFAULT 'parent',
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ── Enfants ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS enfants (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  parent_id   INT NOT NULL,
  nom         VARCHAR(100) NOT NULL,
  prenom      VARCHAR(100) NOT NULL,
  date_naissance DATE NOT NULL,
  sexe        ENUM('M','F') NOT NULL,
  groupe_sanguin VARCHAR(5),
  allergies   TEXT,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ── Vaccins ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS vaccins (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  enfant_id       INT NOT NULL,
  nom             VARCHAR(150) NOT NULL,
  maladie         VARCHAR(150) NOT NULL,
  date_administre DATE NOT NULL,
  medecin         VARCHAR(100),
  lieu            VARCHAR(150),
  lot_numero      VARCHAR(50),
  prochaine_date  DATE,
  notes           TEXT,
  created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
);

-- ── Rendez-vous ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rendezvous (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  enfant_id   INT NOT NULL,
  titre       VARCHAR(200) NOT NULL,
  medecin     VARCHAR(100),
  specialite  VARCHAR(100),
  lieu        VARCHAR(150),
  date_heure  DATETIME NOT NULL,
  statut      ENUM('confirme','enAttente','annule','termine') DEFAULT 'enAttente',
  type        VARCHAR(50) DEFAULT 'presentiel',
  notes       TEXT,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
);

-- ── Croissance ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS croissance (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  enfant_id         INT NOT NULL,
  date_mesure       DATE NOT NULL,
  poids             DECIMAL(5,2) NOT NULL,
  taille            DECIMAL(5,2) NOT NULL,
  perimetre_cranien DECIMAL(5,2),
  notes             TEXT,
  created_at        DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (enfant_id) REFERENCES enfants(id) ON DELETE CASCADE
);
