CREATE TABLE `auth` (
  `username` varchar(255) NOT NULL,
  `otp` varchar(255) NOT NULL,
  `last_accessed` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`username`)
);
