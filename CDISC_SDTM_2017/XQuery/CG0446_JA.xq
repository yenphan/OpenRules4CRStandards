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

(: Rule CG0446 - when TSPARMCD = 'COMPTRT' then TSVALCD is a valid unique ingredient identifier from FDA Substance Registration System (SRS)  :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace xs="http://www.w3.org/2001/XMLSchema";
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
(: let $base := '/db/fda_submissions/cdisc01/'  :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

(: get the TS dataset :)
let $tsdataset := doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']
let $tsdatasetname := $tsdataset/def:leaf/@xlink:href
let $tsdatasetlocation := concat($base,$tsdatasetname)
(: get the OID of the TSPARMCD and TSVALCD variables :)
let $tsparmcdoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TSPARMCD']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
let $tsvalcdoid := (
    for $a in doc(concat($base,$define))//odm:ItemDef[@Name='TSVALCD']/@OID 
    where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name='TS']/odm:ItemRef/@ItemOID
    return $a
)
(: get all the records that have TSPARMCD=COMPTRT :)
for $record in doc($tsdatasetlocation)//odm:ItemGroupData[odm:ItemData[@ItemOID=$tsparmcdoid and @Value='COMPTRT']] 
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of the TSVAL variable :)
    let $tsvalcdvalues := $record/odm:ItemData[@ItemOID=$tsvalcdoid]/@Value
    (:  FOR TESTING let $tsvalcdvalues := ('F43I396OIS') :)
    (: there should be either 0 or 1 TSVALCD values,
    we don't want to call the web service when there is no TSVALCD value:)
    for $tsvalcdvalue in $tsvalcdvalues
        (: invoke the NLM webservice to check whether this is a valid preferred term :)
        let $webservice := concat('https://dailymed.nlm.nih.gov/dailymed/services/v2/uniis.xml?unii_code=',$tsvalcdvalue)
        (: the webservice returns an XML document with the structure /uniis/unii - count the number of unii elements :)
        let $webserviceresult := doc($webservice)
        let $uniicount := count($webserviceresult/uniis/unii)
        (: count the number of active moeities for this code - when 0, the code is invalid :)
        where $uniicount=0
        return <error rule="CG0446" dataset="TS" variable="TSVALCD" rulelastupdate="2017-03-23" recordnumber="{data($recnum)}">Invalid TSVALCD value={data($tsvalcdvalue)} for TSPARMCD=COMPTRT in dataset TS</error>			
		
		