#!/usr/bin/env bash
#Script by: Thiago (ThwyIgo)
#Latest Minecraft version when this was tested: 1.17.1
#THIS IS NOT AN OFFICIAL SCRIPT FROM MOJANG OR MICROSOFT! Use it at your own risk
#O script definitivamente não está pronto, mas ele já funciona na maioria dos casos

#Variáveis de cor
RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
#Funções globais
function askYesNo {
    #Retorna "true" ou "false" em $ANSWER
    QUESTION=$1
    DEFAULT=$2
    if [ "$DEFAULT" = true ]; then
            OPTIONS="[S/n]"
            DEFAULT="s"
        elif [ "$DEFAULT" = false ]; then
            OPTIONS="[s/N]"
            DEFAULT="n"
    else
	OPTIONS="[s/n]"
	DEFAULT="none"
    fi
    read -p "$QUESTION $OPTIONS " -n 1 -s -r INPUT
    #If $INPUT is empty, use $DEFAULT
    INPUT=${INPUT:-${DEFAULT}}
    echo ${INPUT}
    if [[ "$INPUT" =~ ^[sS]$ ]]; then
        ANSWER=true
        elif [[ "$INPUT" =~ ^[nN]$ ]]; then
        ANSWER=false
    else
	echo "Erro. Digite \"s\" ou \"n\""
	askYesNo "$1" "$2"
    fi
}
function checkIfNumber {
    local NUM=$1
    if [[ $NUM =~ ^[0-9]+$ ]]; then
	return 0
    else
	return 1
    fi
}
function selectOptions {
    #Função retorna número da opção em $OPTION e o texto da opção em $S_OPTION
    local OPTIONS=($@)
    local i=0
    while [ $i -lt ${#OPTIONS[@]} ]; do
	echo "$((( ${i} + 1 ))). ${OPTIONS[$i]}"
	i=$((( $i+1 )))
    done
    read -p "Número da opção > " OPTION
    checkIfNumber $OPTION
    if [ $? = 0 ]; then
	if [ $OPTION -le $i ] && [ $OPTION -ge 1 ]; then
	    S_OPTION=${OPTIONS[$((( $OPTION - 1 )))]}
	    #Retornar "-1" indicando sucesso
	    i="-1"
	fi
    fi
    if [ $? = 1 ] || [ $i != "-1" ]; then
	echo -e "\n${RED}Insira uma opção válida${NC}"
	selectOptions $@
    fi
}

echo "Verificando se todos os pacotes necessários estão instalados..."
if [ -z $( which awk ) ]; then
    echo instale o pacote "awk" para continuar
    exit
fi
req_javaver=16
reqpkg=(awk curl grep java sed sudo wget) ;
installed_pkg=( $(which ${reqpkg[@]} | awk -F/ '{ print $NF }') )
#Checar se todos os pacotes necessários estão instalados
if [ "${installed_pkg[*]}" != "${reqpkg[*]}" ]; then
    #Substração de arrays
    diff(){
	awk 'BEGIN{RS=ORS=" "}
       {NR==FNR?a[$0]++:a[$0]--}
       END{for(k in a)if(a[k])print k}' <(echo -n "${!1}") <(echo -n "${!2}")
    }
    #reqpkg - installed_pkg
    not_installed_pkg=($(diff reqpkg[@] installed_pkg[@]))
    echo -e "${RED}Não foram detectados os seguintes pacotes no seu sistema:${NC} ${not_installed_pkg[@]}"
    echo "Por favor, instale-os para prosseguir"
    if [ "$(echo ${not_installed_pkg[@]} | grep -o "java")" = "java" ]; then
	echo "Certifique-se de instalar a versão 16 ou mais recente do java"
    fi
    exit
else
    echo -e "${GREEN}Todos os pacotes necessários foram encontrados!${NC}"
    javaver=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | grep -Eo "[0-9]{2}")
    echo "Versão do java: $javaver"
    if [ $javaver -lt $req_javaver ]; then
	echo -e "${RED}Atualize seu java para pelo menos a versão ${req_javaver} antes de continuar${NC}"
	exit
    else
	echo -e "${GREEN}Seu java está suficientemente atualizado${NC}"
    fi
fi
echo -en "\n"
echo -e "${GREEN}${BOLD}Seja bem-vindo ao script de instalação do minecraft server! (Não oficial)${NORMAL}${NC}"
echo "Por padrão, o script baixará e instalará a versão mais recente do minecraft server. Caso queria instalar uma versão customizada, coloque um arquivo com o nome \"server.jar\" dentro da mesma pasta em que este script está salvo e execute o script novamente."
echo "O arquivo \"server.properties\" será removido caso ele exista no mesmo diretório do script"
read -n 1 -sr -p "Pressione qualquer tecla para iniciar a instação ou \"Ctrl C\" para cancelar..."
echo -en "\n"

#Testar se existe um server.jar na pasta
if [ -f "./server.jar" ]; then
    askYesNo "$(echo -e "${BLUE}Já existe um \"server.jar\" no diretório deste script. Gostaria de fazer a instalação a partir dele?${NC}")" true
    answer_serverfile=$ANSWER
    if [ ${answer_serverfile} = true ]; then
	echo "Utilizando \"server.jar\" local..."
    fi  
fi

#Caso não haja server.jar , ou a resposta tenha sido não
if [ "${answer_serverfile}" != true ]; then
    echo "Baixando \"server.jar\" dos servidores da Mojang..."
    #Baixar o site de download do Minecraft server e extrair o link do "server.jar" mais recente
    #O "user-agent" é necessário para evitar que o acesso seja negado
    #Como o site é muito grande, o "head" faz com que demore menos tempo para que o grep processe o texto
    curl -fo "mcserver-download" --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4495.0 Safari/537.36" https://www.minecraft.net/en-us/download/server && head -n 400 ./mcserver-download | grep -Ezo "Download.{10,600}\/code>" > ./grep-output && rm ./mcserver-download
    #Pegar o link do "server.jar". "{10,100}" serve para evitar que ele pegue a linha inteira, pois há mais de um "jar" na linha
    wget -O server.jar $( grep -Eao "https:.{10,100}[.]jar" ./grep-output )
fi
echo -e "\n"
RAM=1
while [ $RAM = 1 ]; do
    echo -e "Qual a quantidade máxima de RAM (MB) que o servidor utilizará?\nA quantidade mínima recomendada para PCs mais fracos é 1024MB"
    read -p "[Padrão = 1024] > " RAM_max
    RAM_max=${RAM_max:-1024}
    checkIfNumber $RAM_max
    RAM=$?
    if [ $RAM = 0 ]; then
	if [ $RAM_max -lt 1024 ]; then
	    echo -e "${RED}Insira um valor igual ou maior que 1024${NC}"
	    RAM=1
	fi
    else
	echo -e "${RED}Insira apenas números${NC}"
    fi
done
RAM=1
while [ $RAM = 1 ]; do
    echo -e "Qual a quantidade mínima de RAM (MB) que o servidor utilizará?\nA quantidade mínima necessária é 512MB"
    read -p "[Padrão = 512] > " RAM_min
    RAM_min=${RAM_min:-512}
    checkIfNumber $RAM_min
    RAM=$?
    if [ $RAM = 0 ]; then
	if [ $RAM_min -lt 512 ]; then
	    echo -e "${RED}Insira um valor igual ou maior que 512${NC}"
	    RAM=1
	fi
    else
	echo -e "${RED}Insira apenas números${NC}"
    fi
done

echo -ne "#!/usr/bin/env bash\njava -Xmx${RAM_max}M -Xms${RAM_min}M -jar server.jar nogui" > start.sh
echo "Dando permissão de execussão aos arquivos..."
sudo chmod u+x ./start.sh
sudo chmod u+x ./server.jar
echo "Executando \"server.jar\""
rm -f ./eula.txt ./server.properties
bash ./start.sh
#Substituir "true" por "false" na "eula.txt"
EULA_link=$(grep -Eo "https://.*eula" ./eula.txt)
echo -e "\nPara executar um servidor de Minecraft, é preciso aceitar a EULA do Minecraft (Disponível em ${EULA_link})."
askYesNo "Você aceita a EULA? "
if [ $ANSWER = true ]; then
    sed -i "/eula/s/false/true/g" ./eula.txt && echo "Você concordou a EULA"
else
    echo "Você não concordou com a EULA"
    askYesNo "Gostaria de excluir os arquivos gerados durante a instalação?" false
    if [ $ANSWER = true ]; then
	rm -f ./grep-output ./server.properties ./start.sh ./eula.txt
	rm -rd ./logs/
    fi
    echo "Não foi possível completar a instalação"
    exit
fi
#Configurando o servidor
echo -e "\nJá é possível iniciar o servidor utilizando as configurações padrões, mas você pode alterá-las no arquivo \"server.properties\"."
askYesNo "Você gostaria de fazer uma breve configuração do servidor antes de iniciá-lo? " true
if [ $ANSWER = true ]; then
    #Gamemode
    echo -e "\nQual será o modo de jogo?"
    selectOptions Aventura Criativo Espectador Sobrevivência
    echo "Selecionado: $S_OPTION"
    case $OPTION in
	1)
	    GAMEMODE="adventure"
	    ;;
	2)
	    GAMEMODE="creative"
	    ;;
	3)
	    GAMEMODE="spectator"
	    ;;
	4)
	    GAMEMODE="survival"
	    ;;
	*)
	    echo "Erro. Modo de jogo não encontrado"
	    ;;
    esac
    sed -i "/gamemode/s/survival/${GAMEMODE}/" ./server.properties
    #Permitir bloco de comando
    echo -e "\nPermitir blocos de comando?"
    askYesNo "> " false
    if [ $ANSWER = true ];then
	sed -i "/enable-command-block/s/false/true/" ./server.properties
    fi
    #Descrição do servidor
    echo -e "\nQual será a descrição do servidor?"
    read -p "> " motd
    sed -i -e "/motd/s/A\sMinecraft\sServer/${motd}/" ./server.properties
    #Dificuldade
    echo -e "\nQual será a dificuldade?"
    selectOptions Pacífico Fácil Normal Difícil
    echo "Selecionado: ${S_OPTION}"
    case $OPTION in
	1)
	    DIFFICULTY="peaceful"
	    ;;
	2)
	    DIFFICULTY="easy"
	    ;;
	3)
	    DIFFICULTY="normal"
	    ;;
	4)
	    DIFFICULTY="hard"
	    ;;
	*)
	    echo "Erro. Dificuldade não encontrada"
	    ;;
    esac
    sed -i "/difficulty/s/easy/${DIFFICULTY}/" ./server.properties
    #Max players
    i=1
    while [ $i != "0" ]; do
	echo -e "\nQual a quantidade máxima de jogadores que poderão entrar no servidor?"
	read -p "[Padrão = 20] > " MAXPLAYERS
	MAXPLAYERS=${MAXPLAYERS:-20}
	checkIfNumber $MAXPLAYERS
	i=$?
	if [ $i = 0 ]; then
	    if [ $MAXPLAYERS -lt 1 ];then
		echo -e "${RED}O servidor precisa ter espaço para ao menos 1 jogador${NC}"
		i=1
	    fi
	fi
    done
    sed -i "/max-players/s/20/${MAXPLAYERS}/" ./server.properties
    #online-mode
    echo -e "\nVocê deseja desativar o online mode?\nAo desativar o online mode, usuários não precisarão autenticar-se nos servidores da Mojang / Microsoft. Isso normalmente permite que jogadores com Minecraft pirata entrem no servidor"
    askYesNo "Desativar online-mode? " false
    if [ $ANSWER = true ]; then
	sed -i "/online-mode/s/true/false/" ./server.properties
	echo "O online-mode foi desativado"
    fi
    echo -e "\n${GREEN}Configuração completa!${NC}"
fi
rm -f ./grep-output
echo -e "${GREEN}O Minecraft Server foi instalado com sucesso!${NC}\nSempre que você quiser iniciar o servidor, execute o arquivo \"start.sh\""
echo "Deseja iniciar o servidor agora?"
askYesNo "" false
if [ $ANSWER = true ]; then
    ./start.sh
fi
exit
