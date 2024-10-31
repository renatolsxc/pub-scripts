# definicao de uma variavel global para o caminho do arquivo de log que sera usado para acompanhar a execucao
$global:log_file_path = "C:\Windows\temp\atualizaIPpublico.log"
$global:debug_file_path = "C:\Windows\temp\atualizaIPpublico.debug"

function Registrar-Log {
    param (
        [string]$mensagem
    )

    $data_hora = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $log_file_path -Value "$data_hora - $mensagem"
}
function Registrar-Debug {
    param (
        [string]$mensagem
    )

    $data_hora = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $debug_file_path -Value "$data_hora - $mensagem"
}


#configurar paramentros
# zoneid: zona que possue o registro que vamos atualizar
# recordid: registro que vamos atualizar na determinada zona
# uri: a base eh definida pela api da cloudflare e montada com os dados anteriores
# token: eh gerado dentro da conta pessoal de administracao da cloudflare
$zoneid = "028b*************************1912"
$recordid = "61f8b**********************0ed27"
$uri = "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$recordid"
$token = "F_**AsK******************************tA"

#tentar pegar meu ip
# usando um api publica conseguimos pegar nosso ip publico
# se der erro ele sai do script para nao dar erro mais pra frente
# pode dar erro quando a api nao responder ou quando o computador nao estiver conectado a internet
try {
    $meuippublicocompleto = Invoke-RestMethod 'https://api.ipify.org?format=json' -Method 'GET' -Headers $headers
    $meuipp=$meuippublicocompleto.ip
    
} catch {exit 1}


# apenas montar o cabecalho com dados necessarios para envio do path
$Headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# montar o corpo da requisicao com o ip publico do computador
$Body = @{
    "content"  = $meuipp
} | ConvertTo-Json

# tentar enviar a requisicao de atualizacao do registro com o ip publico atual
try {
    $result = Invoke-RestMethod -Uri $uri -Method Patch -Headers $Headers -Body $Body
    Registrar-Log "gravei-ok"
    
    $mensagemcheia = ""
    $nomesdosvalores = $result.result | Get-Member | Where-Object MemberType -eq NoteProperty | Select Name
    $count = ($result.result | Get-Member | Where-Object MemberType -eq NoteProperty | measure-object).Count
    foreach ($nomedovalor in $nomesdosvalores.Name) {
        if ($nomedovalor -ne "Cookies") {
            $valor = $result.result.$nomedovalor
            $mensagemcheia += "$nomedovalor : $valor /\ "
        }
    }
    Registrar-Debug $mensagemcheia

    #Registrar-Debug $result
} catch { 
    $httpResponse = $_.Exception.Response
    Registrar-Log "n-gravei"
    $mensagemcheia = ""
    $nomesdosvalores = $httpResponse | Get-Member | Where-Object MemberType -eq Property | Select Name
    $count = ($httpResponse | Get-Member | Where-Object MemberType -eq Property | measure-object).Count
    
    foreach ($nomedovalor in $nomesdosvalores.Name) {
        if ($nomedovalor -ne "Cookies") {
            $valor = $httpResponse.$nomedovalor
            $mensagemcheia += "$nomedovalor : $valor /\ "
        }
    }
    Registrar-Debug $mensagemcheia
            
    #$httpResponse | Format-List -Property * 
    #Registrar-Debug $httpResponse
}
