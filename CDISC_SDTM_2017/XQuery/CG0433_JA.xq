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

(: When AGEU != null and AGETXT = null then AGE != null  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)
(: Get the DM dataset :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the AGE, AGETXT and AGEU variables (when present) :)
    let $ageoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AGE']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    let $agetxtoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AGETXT']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    let $ageuoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='AGEU']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the DM dataset that have AGEU populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$ageuoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: and get the values of AGE, AGETXT(when populated) and AGEU :)
        let $agevalue := $record/odm:ItemData[@ItemOID=$ageoid]/@Value
        let $agetxtvalue := $record/odm:ItemData[@ItemOID=$agetxtoid]/@Value
        let $ageuvalue := $record/odm:ItemData[@ItemOID=$ageuoid]/@Value
        (: when AGETXT=null must be populated the AGE may not be null :)
        where not($agetxtvalue) and not($agevalue)
        return <error rule="CG0433" dataset="DM" variable="AGE" rulelastupdate="2017-03-22" recordnumber="{data($recnum)}">AGE=null where AGETXT=null and AGEU='{data($ageuvalue)}' is not null</error>				
		
		