-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATED BY Kisha#0001 / slentkat@gmail.com
-- Código disponibilizado no GitHub: https://github.com/haroldogondim/vrp_invoices
-----------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
vCLIENT = Tunnel.getInterface("vrp_invoices")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONEXÃO
-----------------------------------------------------------------------------------------------------------------------------------------
src = {}
Tunnel.bindInterface("vrp_invoices",src)
vCLIENT = Tunnel.getInterface("vrp_invoices")
-----------------------------------------------------------------------------------------------------------------------------------------
-- PREPARE
-----------------------------------------------------------------------------------------------------------------------------------------
vRP._prepare("ksrp/get_invoices_user","SELECT * FROM vrp_invoices WHERE user_id = @user_id AND paid = 0")
vRP._prepare("ksrp/add_invoice","INSERT IGNORE INTO vrp_invoices(user_id,amount,reason,receiver_id,job,expires,createdAt) VALUES(@user_id,@amount,@reason,@receiver_id,@job,@expires,@createdAt)")
vRP._prepare("ksrp/get_invoices_user_value","SELECT SUM(amount) AS value FROM vrp_invoices WHERE user_id = @user_id  AND paid = 0")
vRP._prepare("ksrp/check_invoice_user","SELECT * FROM vrp_invoices WHERE user_id = @user_id AND id = @id  AND paid = 0")
vRP._prepare("ksrp/pay_invoice","UPDATE vrp_invoices SET paid = 1 WHERE user_id = @user_id AND id = @id")
vRP._prepare("ksrp/check_created_invoices","SELECT * FROM vrp_invoices WHERE receiver_id = @receiver_id")
vRP._prepare("ksrp/delete_old_invoices","DELETE FROM vrp_invoices WHERE createdAt < @createdAt AND paid = 1")
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEBHOOK
-----------------------------------------------------------------------------------------------------------------------------------------
local webhookfaturas = "https://discordapp.com/api/webhooks/726081724479570031/CsC-jVv_fHr1nnQzKHDiD2c5JJYSL8IHgSqQA2BWQF2iIIx393YaubnmAFJZJgqXtqEO"
local webhookfaturaspagamento = "https://discordapp.com/api/webhooks/726081676815368223/wXFqdkKUzysajFuGDMMhtlpo72flh23aBO1nHDXw49pnuwWJlwp9C3Mo1qPlIa02CSY8"

function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FATURA
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand('faturas',function(source,args,rawCommand)
	local source = source
	local user_id = vRP.getUserId(source)
	if user_id then
		local profissional = vRP.getUserIdentity(user_id)
		if args[1] == "add" then
			if vRP.hasPermission(user_id,"paramedico.permissao") or vRP.hasPermission(user_id,"mecanico.permissao") or vRP.hasPermission(user_id,"taxista.permissao") or vRP.hasPermission(user_id,"advogado.permissao") or vRP.hasPermission(user_id,"furios.permissao") or vRP.hasPermission(user_id,"admin.permissao") then
				local id = vRP.prompt(source,"Passaporte (da pessoa desejada):","")
				local valor = vRP.prompt(source,"Valor da fatura do passaporte <b>"..id.."</b>:","")
				local motivo = vRP.prompt(source,"Descrição (seja objetivo):","")
				if parseInt(id) <= 0 or parseInt(valor) <= 0 or motivo == "" then
					TriggerClientEvent("Notify",source,"negado","<b>Fatura cancelada</b><br>Divergência nos dados informados.")
					return
				end

				--[[if parseInt(valor) > 50000 then
					TriggerClientEvent("Notify",source,"negado","<b>Fatura cancelada</b><br>O valor da fatura não está condizente com o preço da consulta.")
					return
				end]]
				local job = "Administrador"
				if vRP.hasPermission(user_id,"admin.permissao") then
					job = "Administrador"
				elseif vRP.hasPermission(user_id,"paramedico.permissao") then
					job = "Paramédico"
				elseif vRP.hasPermission(user_id,"mecanico.permissao") then
					job = "Mecânico"
				elseif vRP.hasPermission(user_id,"taxista.permissao") then
					job = "Taxista"
				elseif vRP.hasPermission(user_id,"advogado.permissao") then
					job = "Advogado"
				end

				vRP.execute("ksrp/add_invoice", { user_id = parseInt(id), amount = parseInt(valor), reason = motivo, receiver_id = parseInt(user_id), job = job, expires = os.time() + (60*60*24*3), createdAt = os.time() })
				local identity = vRP.getUserIdentity(parseInt(id))
				local nplayer = vRP.getUserSource(parseInt(id))
				if nplayer then
					SendWebhookMessage(webhookfaturas,"```ini\n[PROFISSIONAL]: "..user_id.." "..profissional.name.." "..profissional.firstname.." \n[===========EMITIU FATURA===========] \n[PASSAPORTE]: "..id.." "..identity.name.." "..identity.firstname.." \n[VALOR]: R$"..vRP.format(parseInt(valor)).." \n[MOTIVO]: "..motivo.." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")

					TriggerClientEvent("Notify",source,"sucesso","Fatura emitida com sucesso.")
					TriggerClientEvent("Notify",nplayer,"importante",profissional.name.." "..profissional.firstname.." emitiu uma fatura pra você com o valor de <b>R$"..vRP.format(parseInt(valor)).." reais</b>.<br><b>Descrição:</b> "..motivo..".")
					vRPclient.playSound(source,"Hack_Success","DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS")
					vRPclient.playSound(nplayer,"Hack_Success","DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS")
				else
					TriggerClientEvent("Notify",source,"negado","O cidadão precisa estar na cidade pra você emitir uma fatura pra ele.")
				end
			else
				TriggerClientEvent("Notify",source,"negado","Você não tem permissão para emitir fatura.")
			end
		elseif args[1] == "pagar" then
			local id_invoice = parseInt(args[2])
			local invoice = vRP.query("ksrp/check_invoice_user",{ user_id = parseInt(user_id), id = id_invoice })
			if invoice[1] ~= nil then
				--if src.isInBank(source) then
					if vRP.request(source,"Deseja pagar a fatura <b>#" .. id_invoice .. "</b> no valor de <b>R$"..vRP.format(parseInt(invoice[1].amount)).."</b>?",30) then	
						if vRP.tryFullPayment(user_id,invoice[1].amount) then
							local consulta_pp = vRP.getUData(parseInt(invoice[1].receiver_id),"vRP:paypal")
							local paypal = json.decode(consulta_pp) or 0
							vRP.giveBankMoney(parseInt(invoice[1].receiver_id),parseInt(invoice[1].amount))
							TriggerClientEvent("Notify",source,"sucesso","A fatura <b>#"..id_invoice.."</b> no valor de <b>R$"..vRP.format(parseInt(invoice[1].amount)).." foi paga com sucesso.")
							vRPclient.playSound(source,"Hack_Success","DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS")
							local nplayer = vRP.getUserSource(parseInt(invoice[1].receiver_id))
							if nplayer then
								TriggerClientEvent("Notify",nplayer,"sucesso","A fatura que você emitiu para <b>"..profissional.name.." "..profissional.firstname.."</b> no valor de <b>R$"..vRP.format(parseInt(invoice[1].amount)).."</b> foi paga com sucesso.")
								vRPclient.playSound(nplayer,"Hack_Success","DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS")
							end
							local profissional_invoice = vRP.getUserIdentity(parseInt(invoice[1].receiver_id))
							SendWebhookMessage(webhookfaturaspagamento,"```ini\n[FATURA]: "..id_invoice.."\n[PAGA POR]: "..user_id.." "..profissional.name.." "..profissional.firstname.."\n[GERADA POR]: "..parseInt(invoice[1].receiver_id).." "..profissional_invoice.name.." "..profissional_invoice.firstname.." \n[VALOR]: R$"..vRP.format(parseInt(invoice[1].amount)).." \n[MOTIVO]: "..invoice[1].reason.." "..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
							vRP.execute("ksrp/pay_invoice", { user_id = user_id, id = id_invoice })
						else
							TriggerClientEvent("Notify",source,"negado","Você não possui dinheiro suficiente no banco para pagar essa fatura.")
						end
					end
				--else
				--	print("false")
				--end
			end
		elseif args[1] == "user" then
			if vRP.hasPermission(user_id,"admin.permissao") or vRP.hasPermission(user_id,"conce.permissao") then
				local user_check = parseInt(args[2])
				local invoices = vRP.query("ksrp/get_invoices_user",{ user_id = parseInt(user_check) })
				if #invoices > 0 then
					for k,v in pairs(invoices) do
						local profissional_invoice = vRP.getUserIdentity(parseInt(v.receiver_id))
						local vencimento = v.expires
						if os.time() > v.expires then
							vencimento = "<b>Vencida</b>"
						else
							vencimento = "<b>Vencimento em " .. vRP.getDayHours(parseInt(v.expires - os.time())) .. "</b>"
						end
						TriggerClientEvent("Notify",source,"importante","Fatura <b>#"..v.id.."</b><br>Gerada por <b>" .. profissional_invoice.name .. " " .. profissional_invoice.firstname .. "</b><br>Valor: <b>$" .. vRP.format(parseInt(v.amount)).. "</b><br>Motivo: <b>" .. v.reason.."</b><br>Status: "..vencimento.."<br>Gerada em: <b>" .. os.date("%d/%m/%Y as %H:%M", v.createdAt).."</b>")
					end
				else
					TriggerClientEvent("Notify",source,"negado","Este cidadão não possui faturas pendentes.")
				end
			end
		elseif args[1] == "check" then
			local invoices = vRP.query("ksrp/check_created_invoices",{ receiver_id = parseInt(user_id) })
			if #invoices > 0 then
				for k,v in pairs(invoices) do
					local profissional_invoice = vRP.getUserIdentity(parseInt(v.receiver_id))
					local vencimento = v.expires
					if os.time() > v.expires then
						vencimento = "<b>Vencida</b>"
					else
						vencimento = "<b>Vencimento em " .. vRP.getDayHours(parseInt(v.expires - os.time())) .. "</b>"
					end
					local paga = "<b>Paga</b>"
					if v.paid == 0 then
						paga = "<b>Em aberto</b>"
					end
					TriggerClientEvent("Notify",source,"importante","Fatura <b>#"..v.id.."</b><br>Status: "..vencimento.."<br>Gerada em: <b>" .. os.date("%d/%m/%Y as %H:%M:%S", v.createdAt).."</b><br>Pagamento: ".. paga)
				end
			else
				TriggerClientEvent("Notify",source,"negado","Você não criou nenhuma fatura.")
			end
		else
			local invoices = vRP.query("ksrp/get_invoices_user",{ user_id = parseInt(user_id) })
			if #invoices > 0 then
				for k,v in pairs(invoices) do
					local profissional_invoice = vRP.getUserIdentity(parseInt(v.receiver_id))
					local vencimento = v.expires
					if os.time() > v.expires then
						vencimento = "<b>Vencida</b>"
					else
						vencimento = "<b>Vencimento em " .. vRP.getDayHours(parseInt(v.expires - os.time())) .. "</b>"
					end
					TriggerClientEvent("Notify",source,"importante","Fatura <b>#"..v.id.."</b><br>Gerada por <b>" .. profissional_invoice.name .. " " .. profissional_invoice.firstname .. "</b><br>Valor: <b>$" .. vRP.format(parseInt(v.amount)).. "</b><br>Motivo: <b>" .. v.reason.."</b><br>Status: "..vencimento.."<br>Gerada em: <b>" .. os.date("%d/%m/%Y as %H:%M", v.createdAt).."</b>")
				end
			else
				TriggerClientEvent("Notify",source,"negado","Você não possui faturas pendentes.")
			end
		end
	end
end)

function cleanOldInvoices()
	vRP.execute("ksrp/delete_old_invoices", { createdAt = (os.time() - (60*60*24*7)) })
end

Citizen.CreateThread(function()
	while true do
	    cleanOldInvoices()
	    Citizen.Wait((60*60)*1000)
	end
end)