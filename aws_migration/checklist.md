AWS Migration Checklist
=======================

## Quick References
* [**Jenkins Master**](#jenkins-master): [Initial](#jenkins-master-phase-1), [Staging](#jenkins-master-phase-2), [Production](#jenkins-master-phase-3)
* [**Jenkins Agent Nodes**](#jenkins-agent-nodes): [Initial](#jenkins-agent-phase-1), [Staging](#jenkins-agent-phase-2), [Production](#jenkins-agent-phase-3)
* [**GitHub Web Hooks**](#github-web-hooks): [Initial](#ghe-webhooks-phase-1), [Staging](#ghe-webhooks-phase-2), [Production](#ghe-webhooks-phase-3)
* [**OpenGrok**](#opengrok): [Initial](#opengrok-phase-1), [Staging](#opengrok-phase-2), [Production](#opengrok-phase-3)
* [**Debug Symbols (PDB) Server for UFT One**](#debug-symbols-pdb-server-for-uft-one): [Initial](#pdb-ufto-phase-1), [Staging](#pdb-ufto-phase-2), [Production](#pdb-ufto-phase-3)
* [**Rubicon**](#rubicon): [Initial](#rubicon-phase-1), [Staging](#rubicon-phase-2), [Production](#rubicon-phase-3)
* Appendixes
  - [Appendix A: AWS Hosts](#appendix-a-aws-hosts)
  - [Appendix B: UFT One Services In AWS Cloud](#appendix-b-uft-one-services-in-aws-cloud)


### Jenkins Master
#### <a name="jenkins-master-phase-1"></a>Phase I - Initiate
- :white_check_mark: Create sever in AWS ([Host](#jenkins-master-host), [IP Address](#jenkins-master-ip))
- :white_check_mark: Deploy Jenkins service ([Serivce port](#jenkins-master-port))

#### <a name="jenkins-master-phase-2"></a>Phase II - Staging
- :white_check_mark: Jenkins web UI service is accessible ([URL](#jenkins-service-url))

#### <a name="jenkins-master-phase-3"></a>Phase III - Production
- :white_large_square: Change URL for all services that need to access the Jenkins master

--------

### Jenkins Agent Nodes
#### <a name="jenkins-agent-phase-1"></a>Phase I - Initiate
- :white_check_mark: Create at least one server for Jenkins agent ([uftJenkinsWin22](#jenkins-agent-host-uftJenkinsWin22))

#### <a name="jenkins-agent-phase-2"></a>Phase II - Staging
- :white_check_mark: Connect to Jenkins master service and accessible by Jenkins jobs
- :white_large_square: Deploy necessary tools and infrastructure for UFT One builds

#### <a name="jenkins-agent-phase-3"></a>Phase III - Production
- :white_large_square: UFT One nightly/CI builds are successfully built on the Jenkins agent nodes

--------

### GitHub Web Hooks
#### <a name="ghe-webhooks-phase-1"></a>Phase I - Initiate
- :white_check_mark: Create sever in AWS ([Host](#ghe-webhooks-host))
- :white_check_mark: Deploy GitHub web hooks service ([Serivce port](#ghe-webhooks-port))
- :white_large_square: Deploy load balance for multiple web hooks backends ([Serivce port](#ghe-webhooks-port))

#### <a name="ghe-webhooks-phase-2"></a>Phase II - Staging
- :white_check_mark: The GitHub web hooks service is accessible ([URL](#ghe-webhooks-payload-url))
- :white_large_square: Configure web hooks in GitHub Enterprise to the web hooks service deployed in AWS cloud, and keep the current running web hooks (deployed in the local lab) as is
- :white_large_square: Modify web hooks config files in `uft.devops` repo, `upgrad_jenkins` branch, and the web hooks work properly when receiving GitHub payloads for the commits in `UFT_2023_0_Migration` branch of UFT One repos
  |      | Git org | Git repo | Event | Jenkins job to be triggered | Comments |
  | ---- | ------- | -------- | ----- | --------------------------- | -------- |
  | :white_large_square: | UFT | UFTBase | `push` | `UFTBase.Build.Launcher` | |
  | :white_large_square: | UFT | UFTBase | `pull_request` | `UFTBase.CompileOnlyBuild.Trigger` | compile-only build |
  | :white_large_square: | UFT | ST | `push` | `ST.Build.Launcher` | |
  | :white_large_square: | UFT | ST | `pull_request` | `ST.CompileOnlyBuild.Trigger` | compile-only build |
  | :white_large_square: | UFT | IBA | `push` | `IBA.Build.Launcher` | |
  | :white_large_square: | UFT | qtp.addins.erp | `push` | `UFT.Agents.Build` | |
  | :white_large_square: | UFT | qtp.addins.webbased | `push` | `UFT.Agents.Build` | |
  | :white_large_square: | UFT | qtp.addins.webbased | `pull_request` | `UFT.Daily.Quick.CI.Launcher` | quick-CI build |
  | :white_large_square: | UFT | qtp.addins.winbased | `push` | `Delphi.Agents.Build` | |
  | :white_large_square: | UFT | qtp.addins.java | `pull_request` | `UFT.Daily.Quick.CI.Launcher` | quick-CI build |
  | :white_large_square: | UFT | qtp.setup | `pull_request` | `UFT.Daily.Quick.CI.Launcher` | quick-CI build |
  | :white_large_square: | UFT | sprinter | `push` | `Sprinter.Build.Launcher` | sprinter build |
  | :white_large_square: | UFTQA | bpt.automation | `push` | `BPT.Automation.ALM.Build` | UFT QA build |
  | :white_large_square: | UFTQA | uft.automation | `push` | `UFTAutomation.Build.Launcher` | UFT QA build |
  | :white_large_square: | Performance-Engineering | UTT | `push` | `UTT.Build.Launcher` | UTT build |

#### <a name="ghe-webhooks-phase-3"></a>Phase III - Production
- :white_large_square: Remove the original web hooks URL (for the service in local lab) from GitHub Enterprise
- :white_large_square: Merge code in `uft.devops` repo, from `upgrad_jenkins` to `master` branch (disable events for `UFT_2023_0_Migration` branch, enable events for `master` and patches branches), and the web hooks service work properly when receiving GitHub payloads from `master` and patches branches
  |      | Git org | Git repo | Event | Jenkins job to be triggered | Comments |
  | ---- | ------- | -------- | ----- | --------------------------- | -------- |
  | :white_large_square: | UFT | UFTBase | `push` | `UFTBase.Build.Launcher` | |
  | :white_large_square: | UFT | UFTBase | `pull_request` | `UFTBase.CompileOnlyBuild.Trigger` | compile-only build |
  | :white_large_square: | UFT | ST | `push` | `ST.Build.Launcher` | |
  | :white_large_square: | UFT | ST | `pull_request` | `ST.CompileOnlyBuild.Trigger` | compile-only build |
  | :white_large_square: | UFT | IBA | `push` | `IBA.Build.Launcher` | |
  | :white_large_square: | UFT | qtp.addins.erp | `push` | `UFT.Agents.Build` | |
  | :white_large_square: | UFT | qtp.addins.webbased | `push` | `UFT.Agents.Build` | |
  | :white_large_square: | UFT | qtp.addins.webbased | `pull_request` | `UFT.Daily.Quick.CI.Launcher` | quick-CI build |
  | :white_large_square: | UFT | qtp.addins.winbased | `push` | `Delphi.Agents.Build` | |
  | :white_large_square: | UFT | qtp.addins.java | `pull_request` | `UFT.Daily.Quick.CI.Launcher` | quick-CI build |
  | :white_large_square: | UFT | qtp.setup | `pull_request` | `UFT.Daily.Quick.CI.Launcher` | quick-CI build |
  | :white_large_square: | UFT | sprinter | `push` | `Sprinter.Build.Launcher` | sprinter build |
  | :white_large_square: | UFTQA | bpt.automation | `push` | `BPT.Automation.ALM.Build` | UFT QA build |
  | :white_large_square: | UFTQA | uft.automation | `push` | `UFTAutomation.Build.Launcher` | UFT QA build |
  | :white_large_square: | Performance-Engineering | UTT | `push` | `UTT.Build.Launcher` | UTT build |

--------

### OpenGrok
#### <a name="opengrok-phase-1"></a>Phase I - Initiate
- :white_check_mark: Create sever in AWS ([Host](#opengrok-host))
- :white_large_square: Deploy OpenGrok service ([Serivce port](#opengrok-port))
- :white_large_square: Deploy load balance for multiple OpenGrok backends ([Serivce port](#opengrok-port))

#### <a name="opengrok-phase-2"></a>Phase II - Staging
- :white_large_square: The OpenGrok service is accessible ([URL](#opengrok-url))
- :white_large_square: All UFT One projects are indexed
- :white_large_square: Peridical sync and index job is enabled and working

#### <a name="opengrok-phase-3"></a>Phase III - Production
N/A

--------

### Debug Symbols (PDB) Server for UFT One
#### <a name="pdb-ufto-phase-1"></a>Phase I - Initiate
- :white_large_square: Create sever in AWS
- :white_large_square: Enable service port

#### <a name="pdb-ufto-phase-2"></a>Phase II - Staging
- :white_large_square: The debug symbol (PDB) server is accessible
- :white_large_square: PDB files are populated
  |      | Module | Comments |
  | ---- | ------ | -------- |
  | :white_large_square: | `qtp` | PDB files for all QTP related repos |
  | :white_large_square: | `lt-tps` | PDB files for all LT-TPS related repos |

#### <a name="pdb-ufto-phase-3"></a>Phase III - Production
N/A

--------

### Rubicon
#### <a name="rubicon-phase-1"></a>Phase I - Initiate
- :white_check_mark: Create sever and storages in AWS by IT/SRE team ([Host](#rubicon-host))
- :white_check_mark: Enable NFS access by IT/SRE team ([NFS URI](#rubicon-nfs-uri))

#### <a name="rubicon-phase-2"></a>Phase II - Staging
- :white_large_square: Make sure all the required/mandatory files for UFT One builds are moved to AWS Rubicon

#### <a name="rubicon-phase-3"></a>Phase III - Production
N/A

--------



## Appendix A: AWS Hosts
| Name | Host | Public Ports | Remarks |
| ---- | ---- | ------------ | ------- |
| Jenkins Master | <a name="jenkins-master-host"></a>`internal-uftojenkins-1210469136.eu-central-1.elb.amazonaws.com`<br/><a name="jenkins-master-ip"></a>`10.168.86.175` | <a name="jenkins-master-port"></a>`443` | Jenkins service is deployed on the host without virtualization technology. |
| Jenkins Agent Node | <a name="jenkins-agent-host-uftJenkinsWin22"></a>`uftJenkinsWin22.uftone.admlabs.aws.swinfra.net` | | Jenkins agent node for UFT One nightly/CI builds |
| GitHub Web Hooks | <a name="ghe-webhooks-host"></a>`uftonewebhook.uftone.admlabs.aws.swinfra.net` | <a name="ghe-webhooks-port"></a>`80` | The GitHub web hooks service is running inside docker and published on the host port. |
| OpenGrok (UFT One) | <a name="opengrok-host"></a>`uftopengrok.uftone.admlabs.aws.swinfra.net` | <a name="opengrok-port"></a>`8080` | The OpenGrok service for UFT One projects. |
| Rubicon | <a name="rubicon-host"></a>`rubicon.cross.admlabs.aws.swinfra.net` | <a name="rubicon-port"></a>`NFS` | The file storage for Rubicon. |

## Appendix B: UFT One Services In AWS Cloud
| Name | URL | Remarks |
| ---- | --- | ------- |
| Jenkins | <a name="jenkins-service-url"></a>[https://internal-uftojenkins-1210469136.eu-central-1.elb.amazonaws.com](https://internal-uftojenkins-1210469136.eu-central-1.elb.amazonaws.com) | Jenkins web UI service |
| GitHub web hooks | <a name="ghe-webhooks-payload-url"></a>[http://uftonewebhook.uftone.admlabs.aws.swinfra.net/](http://uftonewebhook.uftone.admlabs.aws.swinfra.net/) | GitHub web hooks service |
| OpenGrok (UFT One) | <a name="opengrok-url"></a>[http://uftopengrok.uftone.admlabs.aws.swinfra.net:8080/](http://uftopengrok.uftone.admlabs.aws.swinfra.net:8080/) | OpenGrok service for UFT One projects |
| Products on Rubicon | <a name="rubicon-nfs-uri"></a>`\\rubicon.cross.admlabs.aws.swinfra.net\fsx\products` | The `products` folder of Rubicon in AWS cloud. Requires NFS client to access. Command: `mount \\rubicon.cross.admlabs.aws.swinfra.net\fsx\products P:` |
| Docker registry for UFT One | <a name="docker-reg-ufto-url"></a>[https://shcartifactory.swinfra.net/artifactory/adm-ufto-docker/](https://shcartifactory.swinfra.net/artifactory/adm-ufto-docker/) | The docker registry used in AWS cloud. Root URL: [https://shcartifactory.swinfra.net/](https://shcartifactory.swinfra.net/) |
