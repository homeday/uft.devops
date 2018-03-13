#!/bin/bash

script_dir=$(dirname $(readlink -f $0))

scfile="${script_dir}/protect_branches.sh"
org="uft"


name='st'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='uftbase'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches

name='qtp.build'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.components'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.setup'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.mlu'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.doc'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.devutils'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches

name='qtp.infra'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.backend'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.frontend'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.services'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.services.utils'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches

name='qtp.addins.uiautomation'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.teabased'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.qtcustsupport'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.mobile'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.resources'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.winbased'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.webservices'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.webbased'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.flash'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.java'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.erp'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.dotnet'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.te'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.metro'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.core'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches
name='qtp.addins.iba'; "${scfile}" -pdsr "$org/$name" master UFT_12_54_SP_Patches UFT_14_03_SP_Patches

name='qtp.provision'; "${scfile}" -pdsr "$org/$name" master