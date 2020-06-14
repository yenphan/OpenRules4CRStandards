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

(: Rule CG0014: Required variables must always be included in the dataset and cannot be null for any record :)
(: The CDISC Library web service is used to retrieve the required variables for each domain/dataset :)
xquery version "3.0";
declare namespace def = "http://www.cdisc.org/ns/def/v2.0";
declare namespace odm="http://www.cdisc.org/ns/odm/v1.3";
declare namespace data="http://www.cdisc.org/ns/Dataset-XML/v1.0";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
(: function to find out whether a value is in a sequence (array) :)
declare function functx:is-value-in-sequence
  ( $value as xs:anyAtomicType? ,
    $seq as xs:anyAtomicType* )  as xs:boolean {
   $value = $seq
} ;
(: "declare variable ... external" allows to pass $base and $define from an external programm :)
declare variable $base external;
declare variable $define external;
declare variable $datasetname external;
declare variable $username external;
declare variable $password external;
(: let $base := 'LZZT_SDTM_Dataset-XML/' :)
(: let $define := 'define_2_0.xml' :)
(: let $datasetname := 'VS' :)
(: let $datasetname := 'ALL' :)
(: CDISC Library base :)
let $cdisclibrarybase := 'https://library.cdisc.org/api/mdr/'
(: EITHER provide $datasetname=:'ALL', meaning: validate for all datasets referenced from the define.xml OR:
$datasetname:='XX' where XX is a specific dataset, MEANING validate for a single dataset or domain only :)
(:  get the definitions for the domains (ItemGroupDefs in define.xml) :)
let $datasets := (
    if($datasetname != 'ALL') then doc(concat($base,$define))//odm:ItemGroupDef[@Domain=$datasetname or starts-with(@Name,$datasetname)]
    else doc(concat($base,$define))//odm:ItemGroupDef
)
(: the define.xml document itself :)
let $definedoc := doc(concat($base,$define))
(: get the SDTM version :)
let $sdtmigversion := $definedoc//odm:MetaDataVersion[1]/@def:StandardVersion
(: we need to translate the SDTM-IG version in what the CDISC library understands :)
let $sdtmigversion := translate($sdtmigversion,'.','-')
(: iterate over all datasets mentioned in the define.xml :)
for $itemgroup in $datasets
    let $itemgroupoid := $itemgroup/@OID
    let $dataset := $itemgroup/def:leaf/@xlink:href
    let $dsname := $itemgroup/@Name
    let $defclass := $itemgroup/@def:Class
    let $domain := (
    	if ($itemgroup/@domain) then $itemgroup/@domain
		else substring($itemgroup/@Name,1,2)
    )
    (: Unfortunately, the way of writing the class name (casing)
    has not always been consistent within CDISC :)
    let $class := (
    	if(upper-case($defclass)= 'FINDINGS') then 'Findings'
		else if (upper-case($defclass)= 'EVENTS') then 'Events'
        else if (upper-case($defclass)= 'INTERVENTIONS') then 'Interventions'
        else if (starts-with(upper-case($defclass),'TRIAL')) then 'TrialDesign'
        else if (ends-with(upper-case($defclass),'ABOUT')) then 'FindingsAbout'
        else if (starts-with(upper-case($defclass),'SPECIAL')) then 'SpecialPurpose'
        else if (starts-with(upper-case($defclass),'RELAT')) then 'Relationship'
        else 'GeneralObservations'
    )
    let $domain := ( 
    	if($itemgroup/@Domain) then $itemgroup/@Domain
		else $dsname
    )
    let $cdisclibraryquerysdtmig := concat($cdisclibrarybase,'sdtmig/',$sdtmigversion,'/classes/',$class)
    (: now run the CDISC Library query
        as it requires basic authenticatio, 
        we need to use the EXPath 'http-client' extension :)
    let $cdisclibrarysdtmigresponse := http:send-request(<http:request method='get' username='{$username}' password='{$password}' auth-method='Basic'/>, $cdisclibraryquerysdtmig)
    (: make an inventory of the variables that are required using the web service for this domain and SDS version :)
    let $requiredvars := $cdisclibrarysdtmigresponse/json/datasets/*[name=$domain]/datasetVariables/*[core='Req']/name/text()
    (: iterate over the required variables for this dataset,
    and then check whether the variable is populated for each record :)    
    let $datasetpath := concat($base,$dataset)
    let $datasetdoc := doc($datasetpath)  
	(: for the current dataset, we do now have all the required variables, by name,
    but we do need to the OIDs :)
    let $requiredoids := (
        for $a in $itemgroup/odm:ItemRef/@ItemOID
        where $definedoc//odm:ItemDef[@OID=$a and functx:is-value-in-sequence(@Name,$requiredvars)]
        return data($a)
    )
    (: iterate over all the rows, and within the row, 
    	check whether there is a value for it :)
    (: iterate over all the records in the dataset :)
    for $record in $datasetdoc//odm:ItemGroupData
        let $recnum := $record/@data:ItemGroupDataSeq
        (: iterate over all required variable OIDs :)
        for $varoid in $requiredoids
            (: get the name of the variable :)
            let $varname := $definedoc//odm:ItemDef[@OID=$varoid]/@Name
            (: give an error when there is no datapoint ('ItemData') for the required variable :)
            where not($record/odm:ItemData[@ItemOID=$varoid]) 
            return <error rule="CG0014" dataset="{$dsname}" variable="{data($varname)}" rulelastupdate="2020-06-11" recordnumber="{$recnum}">No data found for required variable {data($varname)} in record number {data($recnum)} in dataset {data($datasetname)}</error> 
	 
	