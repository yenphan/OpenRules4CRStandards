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

(: Rule CG0112 - --DOSTXT value is non-numeric :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink"; 
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $datasetname external;
(: let $base := '/db/fda_submissions/cdisc01/' :)
(: let $define := 'define2-0-0-example-sdtm.xml' :)

(: iterate over all the selected datasets , but only the INTERVENTIONS ones :)
for $dataset in doc(concat($base,$define))//odm:ItemGroupDef[upper-case(@def:Class)='INTERVENTIONS'][@Name=$datasetname]
    let $name := $dataset/@Name
    let $dsname := $dataset/def:leaf/@xlink:href
    let $datasetlocation := concat($base,$dsname)
    (: get the OID of the --DOSTXT variables :)
    let $dostxtoid := (
        for $a in doc(concat($base,$define))//odm:ItemDef[ends-with(@Name,'DOSTXT')]/@OID 
        where $a = doc(concat($base,$define))//odm:ItemGroupDef[@Name=$name]/odm:ItemRef/@ItemOID
        return $a
    )
    let $dostxtname := doc(concat($base,$define))//odm:ItemDef[@OID=$dostxtoid]/@Name
    (: iterate over the records in the dataset, but ONLY when --DOSE and --DOSTXT were defined :)
    for $record in doc($datasetlocation)//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: get the (text) value of --DOSTXT (when present) :)
        let $dostxtvalue := $record/odm:ItemData[@ItemOID=$dostxtoid]/@Value
        (: --DOSTXT value may not be numeric :)
        where $dostxtvalue castable as xs:double
        return <error rule="CG0112" dataset="{data($name)}" variable="{data($dostxtname)}" rulelastupdate="2017-02-11" recordnumber="{data($recnum)}">{data($dostxtname)} may not be a numeric value. {data($dostxtname)} = '{data($dostxtvalue)}' was found</error>				
		
		