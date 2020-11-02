## vrp_invoices

Script feito por mim utilizando o framework vRP para substituir o PayPal no FiveM. Além de poder criar faturas, você pode bloquear o player de utilizar outras ferramentas caso tenha faturas pendentes. Alguns ajustes como permissões devem ser alteradas de acordo com suas necessidades.

## SQL: 
```
CREATE TABLE IF NOT EXISTS `vrp_invoices` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `amount` int(11) NOT NULL,
  `reason` text NOT NULL,
  `receiver_id` int(11) NOT NULL,
  `paid` int(11) NOT NULL DEFAULT 0,
  `job` varchar(255) NOT NULL,
  `expires` int(11) NOT NULL,
  `createdAt` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `vrp_invoices`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `vrp_invoices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;
```

Mais informações no [Discord do KS Network](https://discord.gg/GsQNwaP)
