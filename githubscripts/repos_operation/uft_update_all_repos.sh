#!/bin/bash

script_dir=$(dirname $(readlink -f $0))

scfile="${script_dir}/update_repo.sh"
org="uft"


name='st'; desc='ST (a.k.a. API Test)'; "${scfile}" -mrd"$desc" "$org" "$name"
name='uftbase'; desc='UFTBase'; "${scfile}" -mrd"$desc" "$org" "$name"

name='qtp.build'; desc='QTP main build repository'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.components'; desc='components'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.setup'; desc='SetupBuilder except MLU assets'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.mlu'; desc='SetupBuilder/Input/UFT_MLU'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.doc'; desc='Doc'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.devutils'; desc='DevUtils'; "${scfile}" -mrd"$desc" "$org" "$name"

name='qtp.infra'; desc='QTP/Infra'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.backend'; desc='QTP/BackEnd'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.frontend'; desc='QTP/FrontEnd'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.services'; desc='QTP/Services except Utils subdirectory'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.services.utils'; desc='QTP/Services/Utils'; "${scfile}" -mrd"$desc" "$org" "$name"

name='qtp.addins.uiautomation'; desc='QTP/Addins/UIAutomation'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.teabased'; desc='QTP/Addins/TEABased'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.qtcustsupport'; desc='QTP/Addins/QTCustSupport'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.mobile'; desc='QTP/Addins/MobilePackage'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.resources'; desc='QTP/Addins/AddinsResources'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.winbased'; desc='QTP/Addins/WinBased'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.webservices'; desc='QTP/Addins/WebServices'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.webbased'; desc='QTP/Addins/WebBased'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.flash'; desc='QTP/Addins/Flash (a.k.a. FlexPackage)'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.java'; desc='QTP/Addins/Java'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.erp'; desc='QTP/Addins/ERP'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.dotnet'; desc='QTP/Addins/DotNet'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.te'; desc='QTP/Addins/TePackage'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.metro'; desc='QTP/Addins/Metro'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.core'; desc='QTP/Addins/CoreAddins'; "${scfile}" -mrd"$desc" "$org" "$name"
name='qtp.addins.iba'; desc='QTP/Addins/IBAPackage'; "${scfile}" -mrd"$desc" "$org" "$name"

name='qtp.provision'; desc='Provision QTP repositories'; "${scfile}" -mrd"$desc" "$org" "$name"

name='uft.demo.play'; desc='A demo project in UFT organization free for playing'; "${scfile}" -mrd"$desc" "$org" "$name"

name='sprinter'; desc='Sprinter'; "${scfile}" -mrd"$desc" "$org" "$name"
