# dyndns
# Script para atualizar host remoto no site dyndns
# Development by: Jayron Castro
# Date: 21/08/2022 20:29
# eMail: jayroncastro@gmail.com
{
  #======== VARIÁVEIS DE CONTROLE =========
  #ddnsuser: recebe o nome de usuario para autenticar no dyndns;
  #ddnspwd: recebe a senha do usuário para autenticar no dyndns;
  #ddnshost: recebe o host a ter o ip atualizado pelo script;
  #localInterface: recebe o nome da interface local por onde a comunicação com a internet irá ocorrer.
  #=======================================
  :global ddnsuser        "kstros";
  :global ddnspwd         "noryaj1977jacc";
  :global ddnshost        "pfeitosabackup1.dnsalias.org";
  :global localInterface  "pppoe-bital-100Mb-Full";
  #=======================================
  #=======================================
  #======== FUNÇÕES GLOBAIS =========
  #Retorna o IP armazenado no arquivo especificado
  :global getContentFile do={
    :return ([/file get [find where name=$localFile] value-name=contents]);
  };
  #Retorna o nome do arquivo
  :global getFileName do={
    :global ddnshost;
    :return ([:tostr [:pick $ddnshost 0 ([:find $ddnshost "." -1])]] . ".txt");
  };
  #Retorna o ip local da interface
  :global getLocalIP do={
    :global localInterface;
    :local localIP [/ip address get [find interface=$localInterface] address];
    :return ([:toip ([:pick $localIP 0 ([:tonum ([:len $localIP])] - 3)])]);
  };
  #Retorna o IP externo do link armazenado no arquivo de download
  :global getExternalIP do={
    :global getLocalIP;
    :global externalIPFile;
    :global getContentFile;
    #Vai no site da kstros e recebe um arquivo com o ip válido do link
    /tool fetch src-address=[$getLocalIP] mode=http dst-path=$externalIPFile address=[:resolve www.kstros.com] port=80 host=www.kstros.com src-path=("/meuip.php");
    :log debug "Local file created to store public ip: $externalIPFile";
    #Interrompe execução para gravar o arquivo em disco
    /delay 1;
    :return ([:toip [$getContentFile localFile=$externalIPFile]]);
  };
  #Retorna o IP temporário do link armazenado no arquivo de download
  :global getTemporaryIP do={
    :global createTemporaryFileIfNotExists;
    :global temporaryFile;
    :global getContentFile;
    #Cria o arquivo temporario, caso o mesmo nao exista
    [$createTemporaryFileIfNotExists];
    :return ([:toip [$getContentFile localFile=$temporaryFile]]);
  };
  #Retorna verdadeiro se o arquivo existe
  :global fileExists do={
    :local result;
    :if ([:len [/file find where name=$fileName]] < 1) do={
      :set result false;
    } else={
      :set result true;
    };
    :return $result;
  };
  #Retorna verdadeiro se o processo de atualização foi concluído com sucesso
  :global isProcessConcluded do={
    :global fileExists;
    :global updateStatusFile;
    :global getContentFile;
    :local result;
    :if ([$fileExists fileName=$updateStatusFile]) do={
      :local contentFile;
      :set contentFile [:pick [$getContentFile localFile=$updateStatusFile] 0 4];
      :if ($contentFile = "good") do={
        :log debug "Update process took place normally and ip was changed successfully";
      } else={
        :if ($contentFile = "noch") do={
          :log debug "Update process occurred normally but the ip did not change";
        }
      }
      :if (($contentFile = "good") || ($contentFile = "noch")) do={
        :set result true;
      } else={
        :set result false;
      };
    } else={
      :set result false;
    };
    :return $result;
  };
  #=======================================
  #== CONSTANTES E VARIÁVEIS DE KERNEL ==
  # "timeDelay" tem seu valor expresso em segundos
  #=======================================
  :global externalIPFile;
  :global temporaryFile;
  :global updateStatusFile;
  #=======================================
  :set $externalIPFile ("ext_" . [$getFileName]);
  :set $temporaryFile ("tmp_" . [$getFileName]);
  :set $updateStatusFile ("_" . [$getFileName]);
  #=======================================
  #======== ROTINAS GLOBAIS =========
  #Cria o arquivo temporário caso o mesmo não exista
  :global createTemporaryFileIfNotExists do={
    :global temporaryFile;
    :global fileExists;
    #Verifica se existe o arquivo temporario de retorno do dyndns
    :if (![$fileExists fileName=$temporaryFile]) do={
      :log error "criando";
      /file print file=$temporaryFile where name=$temporaryFile;
      /delay 1;
      /file set $temporaryFile contents="0.0.0.0";
      /delay 1;
      :log debug "Local file created to store temporary ip: $temporaryFile";
    };
  };
  #Atualiza o host remoto com o novo ip
  :global updateRemoteHostIP do={
    :global ddnshost;
    :global getLocalIP;
    :global updateStatusFile;
    :global ddnsuser;
    :global ddnspwd;
    :log debug "Remote host to be updated: $ddnshost";
      :local connectionString "/nic/update\?hostname=$ddnshost&myip=$externalIP&wildcard=NOCHG&mx=NOCHG&backmx=NOCHG";
      #Atualiza o dyndns
      /tool fetch src-address=[$getLocalIP] mode=http port=80 dst-path=$updateStatusFile address=[:resolve members.dyndns.org] host=members.dyndns.org src-path=$connectionString  user=$ddnsuser password=$ddnspwd;
      :log debug "local file created to store the result of the update process: $updateStatusFile";
      #força parada para aguardar criação do arquivo
      /delay 1;
  };
  #Escreve conteúdo no arquivo especificado
  :global writeContentToFile do={
    :global temporaryFile;
    /file set $temporaryFile contents=$externalIP;
    #força parada para escrever no arquivo
    /delay 1;
  }

  #========== REGRA DE NEGÓCIO ==========
  #======================================
  #Executa o scrip somente se a interface estiver habilitada
  :if (!([/interface get $localInterface disabled])) do={
    :log debug "Interface $localInterface enabled normally and the script started the update process :)";
    #Armazena na variável o ip externo do link
    :local externalIP;
    :local temporaryIP;
    :set externalIP [$getExternalIP];
    :set temporaryIP [$getTemporaryIP];
    :log debug "External IP: $externalIP";
    :log debug "Temporary IP: $temporaryIP";
    :if ($externalIP != $temporaryIP) do={
      :log info "Starting external host ip update process, old ip $temporaryIP will change to $externalIP";
      [$updateRemoteHostIP externalIP=$externalIP];
      :if ([$isProcessConcluded]) do={
        [$writeContentToFile externalIP=$externalIP]
        :log info "Remote host $ddnshost update process was successful. :)";
      } else={
        :log error "Some error occurred in the remote host update process, check network layer and dyndns access data";
      };
    } else={
      :log warning "No need to update external IP!!! :)";
    };
  } else={
    :log warning "interface $localInterface disabled, so ddns update script will not run!!! :(";
  };
}