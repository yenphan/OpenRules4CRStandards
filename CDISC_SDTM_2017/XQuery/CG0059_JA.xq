(: Copyright 2020 Jozef Aerts.
Licensed under the Apache License, Version 2.0 (the "License");
You may not use this file except in compliance with the License.
You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, 
software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
:)

(: Rule CG0059 When --STTPT != null then --STRTPT != null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external; 
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
let $definedoc := doc(concat($base,$define))
(: Iterate over all datasets defined in the define.xml :)
for $itemgroupdef in $definedoc//odm:ItemGroupDef
    let $name := $itemgroupdef/@Name
    let $domain := (
        if($itemgroupdef/@Domain) then $itemgroupdef/@Domain
        else $name
    )
    (: find the OID and name of the --STTPT variable /(if any) :)
    let $sttptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STTPT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $sttptname := $definedoc//odm:ItemDef[@OID=$sttptoid]/@Name
    (: and of the --STRTPT variable :)
    let $strtptoid := (
        for $a in $definedoc//odm:ItemDef[ends-with(@Name,'STRTPT')]/@OID 
        where $a = $itemgroupdef/odm:ItemRef/@ItemOID
        return $a
    )
    let $strtptname := $definedoc//odm:ItemDef[@OID=$strtptoid]/@Name
    (: get the location of the dataset :)
    let $dataset := $itemgroupdef/def:leaf/@xlink:href
    let $datasetdoc := doc($dataset)
    (: iterate over all the records that do have an --STTPT record, but only for those datasets for which --STTPT and --STRTPT have been defined :)
    for $record in $datasetdoc[$sttptoid and $strtptoid]//odm:ItemGroupData[odm:ItemData[@ItemOID=$sttptoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of the --STTPT variable :)
        let $sttptvalue := $record/odm:ItemData[@ItemOID=$sttptoid]/@Value
        (: get the value of the --STRTPT variable (if any) :)
        let $strtptvalue := $record/odm:ItemData[@ItemOID=$strtptoid]/@Value
        (: give an error when there is a --STTPT value but no --STRTPT value :)
        where $sttptvalue and not($strtptvalue)
    return <error rule="CG0059" variable="{data($strtptname)}" dataset="{$name}" rulelastupdate="2017-02-05" recordnumber="{data($recnum)}">No value for {data($strtptname)} was found although there is a value for {data($sttptname)}={data($sttptvalue)}</error>			
		