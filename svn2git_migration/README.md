# UFT SVN To GitHub Enterprise Migration

## Table Of Contents
* [Preparation: GitHub Enterprise](#prep-github)
* [Migration: QTP](#qtp-mig)
    - [Build Preparation: QTP](#qtp-build-prep)


## <a name="prep-github"></a>Preparation: GitHub Enterprise
1. Follow the [Github instructions](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) to create a new personal access token and record the token. When selecting permissions, ensure selecting the full permissions for `admin:org, repo, user`. This token will be used in API call.

2. Create a new organization `uft`

3. Add all members and add at least one team called `viewers` to the new organization

4. Navigate to **Settings --> Member privileges** tab of the new organization, select `Write` option in **Default repository permission** section


## <a name="qtp-mig"></a>Migration: QTP
1. Check out or export all source code of QTP from SVN server

2. Review/Update all the repositories to be splitted in files **qtp.migration.final.*.yaml**.

3. For the repository **QTP.Addins.Flex** (QTP/Addins/Flash), skip the directories **QTP\Addins\Flash\FlexPackage\app\apache-flex-sdk-4-14-hp-mod** and **QTP\Addins\Flash\FlexPackage\app\apache-flex-sdk-hp-mod**. Copy these two directories to Nexus storage.

4. Add **.gitignore** file for each migrated git repository.

5. Add tag(s) for each migrated git repository.


### <a name="qtp-build-prep"></a>Build Preparation After Migration: QTP
Since repositories are splitted, some additional works are required in order to make CI/CD build works.

#### (REQUIRED!) QTP.FrontEnd.RainbowLic & QTP.FrontEnd.License
This standalone repository has some dependencies on the directories and files in the **QTP\QTP_OUTPUT_DIR** directory. However, with this migration, the entire **QTP\QTP_OUTPUT_DIR** directory will be excluded and no GIT repository will be created.

In this case, the entire directory **QTP\QTP_OUTPUT_DIR\include** shall be moved to `QTP.FrontEnd.RainbowLic` and also repository, except the file **QTP\QTP_OUTPUT_DIR\include\build.cs**. Then add pre-build event(s) in the corresponding project(s) in order to copy the **include** directory in **QTP\QTP_OUTPUT_DIR** before building any project in this repository. It keeps the CI/CD build system unmodified that way.

#### (REQUIRED!) QTP.Infra
Since the entire **QTP\QTP_OUTPUT_DIR** directory will be excluded and no GIT repository will be created, the file **QTP\QTP_OUTPUT_DIR\lib\libmercrypt_D.lib** shall be moved in a repository so that those who are using this file can be found it after migration.

In this case, just move this file to the repository `QTP.Infra`, under **MockLRDebug** directory.

#### (Optional) QTP.Addins.AddinsResources & QTP.Addins.QTCustSupport
This one is splitted as a standalone repository. Currently there is no **build_jenkins.proj** file in this repository and the build is triggered by another repository `QTP.Addins.QTCustSupport`.

In order to split the repository entirely and remove the dependencies between others, it is recommended to add a new **build_jenkins.proj** file in this repository, remove the invocation from the build file in `QTP.Addins.QTCustSupport` repository and then make relevant changes accordingly in CI/CD build system.


