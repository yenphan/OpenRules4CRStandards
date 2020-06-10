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

(: Rule CG0206 - SE - When ETCD = 'UNPLAN' then TAETORD = null :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare variable $base external;
declare variable $define external; 
(: let $base := '/db/fda_submissions/cdiscpilot01/'  :)
(: let $define := 'define_2_0.xml' :)
let $definedoc := doc(concat($base,$define))
(: get the SE dataset definition :)
let $seitemgroupdef := $definedoc//odm:ItemGroupDef[@Name='SE']
(: and the dataset location :)
let $sedatasetlocation := $seitemgroupdef/def:leaf/@xlink:href
let $sedatasetdoc := doc(concat($base,$sedatasetlocation))
(: we need the OID of ETCD and of TAETORD :)
let $etcdoid := (
    for $a in $definedoc//odm:ItemDef[@Name='ETCD']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
let $taetordoid := (
    for $a in $definedoc//odm:ItemDef[@Name='TAETORD']/@OID 
        where $a = $seitemgroupdef/odm:ItemRef/@ItemOID
        return $a
)
(: iterate over all the records in the dataset for which ETCD = 'UNPLAN' :)
for $record in $sedatasetdoc//odm:ItemGroupData[odm:ItemData[@ItemOID=$etcdoid and @Value='UNPLAN']]
    let $recnum := $record/@data:ItemGroupDataSeq
    (: get the value of TAETORD (if any) :)
    let $taetord := $record/odm:ItemData[@ItemOID=$taetordoid]/@Value
    (: TAETORD must be null :)
    where $taetord  (: TAETORD is not null :)
    return <error rule="CG0206" dataset="SE" rulelastupdate="2017-02-23" variable="TAETORD" recordnumber="{data($recnum)}" >A non-null value for TAETORD={data($taetord)} was found in combination with ETCD='UNPLAN'</error>	
		
		