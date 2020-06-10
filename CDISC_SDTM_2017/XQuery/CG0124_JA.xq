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

(: Rule CG0124 - When ACTARMCD not in TA.ARMCD then ACTARMCD in ('SCRNFAIL', 'NOTASSGN', 'NOTTRT', 'UNPLAN') :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external; 
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: let $base := '/db/fda_submissions/cdiscpilot01/'  :)
(: let $define := 'define_2_0.xml' :)

(: get the TA dataset and the ARMCD OID in TA :)
let $tadataset := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TA']
let $tadatasetname := $tadataset/def:leaf/@xlink:href
let $tadatasetlocation := concat($base,$tadatasetname)
let $armcdfromtaoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ARMCD']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TA']/odm:ItemRef/@ItemOID
    return $a
)
(: make an array/sequence with all TA-ARMCD values, take it from the dataset itself, not from the define.xml codelist :)
let $armcdsequence := distinct-values(
    for $itemdata in doc($tadatasetlocation)//odm:ItemGroupData/odm:ItemData[@ItemOID=$armcdfromtaoid]
    return $itemdata/@Value
)
(: Get the DM dataset :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']
    let $datasetname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$datasetname)
    (: get the OID of the ACTARMCD, and BRTHDTC (when present) :)
    let $actarmcdoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[@Name='ACTARMCD']/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='DM']/odm:ItemRef/@ItemOID
        return $a
    )
    (: iterate over all the records in the DM dataset that have ACTARMCD populated :)
    for $record in doc($datasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$actarmcdoid]]
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the value of ACTARMCD :)
        let $actarmcdvalue := $record/odm:ItemData[@ItemOID=$actarmcdoid]/@Value
        (: When ACTARMCD not in TA.ARMCD then ACTARMCD in ('SCRNFAIL', 'NOTASSGN', 'NOTTRT', 'UNPLAN') :)
        where not(functx:is-value-in-sequence($actarmcdvalue,$armcdsequence)) and not($actarmcdvalue='SCRNFAIL') and not($actarmcdvalue='NOTASSGN') and not($actarmcdvalue='NOTTRT') and not($actarmcdvalue='UNPLAN')
        return <error rule="CG0124" dataset="DM" variable="ACTARMCD" rulelastupdate="2017-02-18" recordnumber="{data($recnum)}">Invalid value for ACTARMCD, value={data($actarmcdvalue)} in dataset DM is not found in TA.ARMCD and is not one of ('SCRNFAIL', 'NOTASSGN', 'NOTTRT', 'UNPLAN')</error>				
		
		