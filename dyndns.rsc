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
  #localInterface: recebe o nome da interface local por onde a comunicação com a internet irá ocorrer, caso não seja especificada o script usuará a interface de saída padrão.
  #=======================================
  :global ddnsuser        "usuario";
  :global ddnspwd         "senha";
  :global ddnshost        "qualquer-ddns";
  :global localInterface  "";
  #=======================================
  #== CONSTANTES E VARIÁVEIS DE KERNEL ==
  #=======================================
  :global externalIPFile;
  :global temporaryFile;
  :global updateStatusFile;
  #=======================================
  #======== FUNÇÕES GLOBAIS =========
  #Retorna o IP armazenado no arquivo especificado
  :global getContentFile do={
    :local contentFile;
    :log debug "starting routine routine getContentFile";
    :set contentFile [/file get [find where name=$localFile] value-name=contents];
    :log debug "getContentFile->contentFile: $contentFile";
    :log debug "ending routine getContentFile";
    :return $contentFile;
  };
  #Retorna o nome do arquivo
  :global getFileName do={
    :global ddnshost;
    :return ([:tostr [:pick $ddnshost 0 ([:find $ddnshost "." -1])]] . ".txt");
  };
  #Retorna o ip local da interface
  :global getLocalIP do={
    :global localInterface;
    :local localIP;
    :log debug "starting routine routine getLocalIP";
    :log debug "getLocalIP->localInterface: $localInterface";
    :set localIP [/ip address get [find interface=$localInterface] address];
    :set localIP [:toip ([:pick $localIP 0 ([:tonum ([:len $localIP])] - 3)])];
    :log debug "getLocalIP->localIP: $localIP";
    :log debug "ending routine getLocalIP";
    :return $localIP;
  };
  #Retorna o IP externo do link armazenado no arquivo de download
  :global getExternalIP do={
    :global getLocalIP;
    :global externalIPFile;
    :global getContentFile;
    :local localIP;
    :global isStandardInterface;
    :log debug "starting routine routine getExternalIP";
    #testa para saber se o script vai tratar uma interface específica ou a padrão
    :if ([$isStandardInterface]) do={
      #Vai no site da kstros e recebe um arquivo com o ip válido do link
      /tool fetch mode=http dst-path=$externalIPFile address=[:resolve www.kstros.com] port=80 host=www.kstros.com src-path=("/meuip.php");
    } else={
      :set localIP [$getLocalIP];
      :log debug "getExternalIP->localIP1: $localIP";
      #Vai no site da kstros e recebe um arquivo com o ip válido do link
      /tool fetch src-address=$localIP mode=http dst-path=$externalIPFile address=[:resolve www.kstros.com] port=80 host=www.kstros.com src-path=("/meuip.php");
    };
    :log debug "getExternalIP->externalIPFile: $externalIPFile";
    :log debug "Local file created to store public ip: $externalIPFile";
    #Interrompe execução para gravar o arquivo em disco
    /delay 1;
    :log debug "ending routine getExternalIP";
    :return ([:toip [$getContentFile localFile=$externalIPFile]]);
  };
  #Retorna o IP temporário do link armazenado no arquivo de download
  :global getTemporaryIP do={
    :global createTemporaryFileIfNotExists;
    :global temporaryFile;
    :global getContentFile;
    :log debug "starting routine routine getTemporaryIP";
    #Cria o arquivo temporario, caso o mesmo nao exista
    [$createTemporaryFileIfNotExists];
    :log debug "ending routine getTemporaryIP";
    :return ([:toip [$getContentFile localFile=$temporaryFile]]);
  };
  #Retorna verdadeiro se o arquivo existe
  :global fileExists do={
    :local result;
    :log debug "starting routine routine fileExists";
    :if ([:len [/file find where name=$fileName]] < 1) do={
      :set result false;
    } else={
      :set result true;
    };
    :log debug "fileExists->result: $result";
    :log debug "ending routine fileExists";
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
  :global isStandardInterface do={
    :local result;
    :global localInterface;
    :if ([:len $localInterface] = 0) do={
      :set result true;
    } else={
      :set result false;
    };
    return $result;
  };
  #=======================================
  #=======================================
  #======== ROTINAS GLOBAIS =========
  #Carrega o nome dos arquivos locais
  :global createLocalFileName do={
    :global externalIPFile;
    :global temporaryFile;
    :global updateStatusFile;
    :global getFileName;
    :set $externalIPFile ("ext_" . [$getFileName]);
    :set $temporaryFile ("tmp_" . [$getFileName]);
    :set $updateStatusFile ("_" . [$getFileName]);
  };
  #Cria o arquivo temporário caso o mesmo não exista
  :global createTemporaryFileIfNotExists do={
    :global temporaryFile;
    :global fileExists;
    :log debug "starting routine routine createTemporaryFileIfNotExists";
    #Verifica se existe o arquivo temporario de retorno do dyndns
    :if (![$fileExists fileName=$temporaryFile]) do={
      :log debug "creating local file to store temporary ip";
      /file print file=$temporaryFile where name=$temporaryFile;
      /delay 1;
      :log debug "Local file created to store temporary ip: $temporaryFile";
      /file set $temporaryFile contents="0.0.0.0";
      /delay 1;
      :log debug "local file content to store changed temporary ip.";
    };
    :log debug "ending routine createTemporaryFileIfNotExists";
  };
  #Atualiza o host remoto com o novo ip
  :global updateRemoteHostIP do={
    :global ddnshost;
    :global getLocalIP;
    :global updateStatusFile;
    :global ddnsuser;
    :global ddnspwd;
    :global isStandardInterface;
    :log debug "Remote host to be updated: $ddnshost";
      :local connectionString "/nic/update\?hostname=$ddnshost&myip=$externalIP&wildcard=NOCHG&mx=NOCHG&backmx=NOCHG";
      #Atualiza o dyndns
      :if ([$isStandardInterface]) do={
        /tool fetch mode=http port=80 dst-path=$updateStatusFile address=[:resolve members.dyndns.org] host=members.dyndns.org src-path=$connectionString  user=$ddnsuser password=$ddnspwd;
      } else={
        /tool fetch src-address=[$getLocalIP] mode=http port=80 dst-path=$updateStatusFile address=[:resolve members.dyndns.org] host=members.dyndns.org src-path=$connectionString  user=$ddnsuser password=$ddnspwd;
      };
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
  #Cria nomes dos arquivos locais
  [$createLocalFileName];
  #Armazena na variável o ip externo do link
  :local externalIP;
  :local temporaryIP;
  #Retorna o ip externo
  :set externalIP [$getExternalIP];
  #Retorna o ip temporário
  :set temporaryIP [$getTemporaryIP];
  :log debug "External IP: $externalIP";
  :log debug "Temporary IP: $temporaryIP";
  :if ($externalIP != $temporaryIP) do={
    :log info "Starting external host ip update process, old ip $temporaryIP will change to $externalIP";
    #Atualiza o host ddns especificado
    [$updateRemoteHostIP externalIP=$externalIP];
    #Entra na instrução somente se o processo de atualização ocorrer sem erros
    :if ([$isProcessConcluded]) do={
      #Escreve o novo ip no arquivo local
      [$writeContentToFile externalIP=$externalIP];
      :log warning "Remote host $ddnshost update process was successful. :)";
    } else={
      :log error "Some error occurred in the remote host update process, check network layer and dyndns access data";
    };
  } else={
    :log info "No need to update external IP $externalIP to ddns $ddnshost!!! :)";
  };
}