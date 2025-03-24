*======================PROGRAM: MHI_FORMATS.SAS==============================;
*
* DESCRIPTION: Creates format library for AHRQ Maternal Health Indicators
*
* VERSION: SAS Beta version of MHI v2024
* RELEASE DATE: SEPTEMBER 2024
* 
*============================================================================;

 *SAS option to print program text to log disabled to avoid filling log window;
 %let orgoptionValue = %sysfunc(getoption(source));  
 option nosource; 

proc format LIBRARY=LIBRARY;

    /* Numerator MHI DX and PR codes */

    /* 1. Acute myocardial infarction ICD-10  DX*/
    Value $DX_Acute_MyoCard_Infarct
        'I2101'                 /*ST elevation (STEMI) myocardial infarction involving left main coronary artery*/
        ,'I2102'                /*ST elevation (STEMI) myocardial infarction involving left anterior descending coronary artery*/
        ,'I2109'                /*ST elevation (STEMI) myocardial infarction involving other coronary artery of anterior wall*/
        ,'I2111'                /*ST elevation (STEMI) myocardial infarction involving right coronary artery*/
        ,'I2119'                /*ST elevation (STEMI) myocardial infarction involving other coronary artery of inferior wall*/
        ,'I2121'                /*ST elevation (STEMI) myocardial infarction involving left circumflex coronary artery*/
        ,'I2129'                /*ST elevation (STEMI) myocardial infarction involving other sites*/
        ,'I213'                 /*ST elevation (STEMI) myocardial infarction of unspecified site*/
        ,'I214'                 /*Non-ST elevation (NSTEMI) myocardial infarction*/
        ,'I219'                 /*Acute myocardial infarction, unspecified*/
        ,'I21A1'                /*Acute myocardial infarction type 2*/
        ,'I21A9'                /*Other myocardial infarction type*/
        ,'I21B'                 /*Myocardial infarction with coronary microvascular dysfunction*/
        ,'I220'                 /*Subsequent ST elevation (STEMI) myocardial infarction of anterior wall*/
        ,'I221'                 /*Subsequent ST elevation (STEMI) myocardial infarction of inferior wall*/
        ,'I222'                 /*Subsequent non-ST elevation (NSTEMI) myocardial infarction*/
        ,'I228'                 /*Subsequent ST elevation (STEMI) myocardial infarction of other sites*/
        ,'I229 ' = '1'          /*Subsequent ST elevation (STEMI) myocardial infarction of unspecified site*/
        OTHER = '0';

    /* 2. Aneurysm ICD-10 DX*/
    Value $DX_Aneurysm
        'I7100'                 /*Dissection of unspecified site of aorta*/
        ,'I7101'                /*Dissection of thoracic aorta*/
        ,'I71010'               /*Dissection of ascending aorta*/
        ,'I71011'       /*Dissection of aortic arch*/
        ,'I71012'       /*Dissection of descending thoracic aorta*/
        ,'I71019'       /*Dissection of thoracic aorta, unspecified*/
        ,'I7110'        /*Thoracic aortic aneurysm, ruptured, unspecified*/
        ,'I7111'        /*Aneurysm of the ascending aorta, ruptured*/
        ,'I7112'        /*Aneurysm of the aortic arch, ruptured*/
        ,'I7113'        /*Aneurysm of the descending thoracic aorta, ruptured*/
        ,'I7120'        /*Thoracic aortic aneurysm, without rupture, unspecified*/
        ,'I7121'        /*Aneurysm of the ascending aorta, without rupture*/
        ,'I7122'        /*Aneurysm of the aortic arch, without rupture*/
        ,'I7123'        /*Aneurysm of the descending thoracic aorta, without rupture*/
        ,'I7130'        /*Abdominal aortic aneurysm, ruptured, unspecified*/
        ,'I7131'        /*Pararenal abdominal aortic aneurysm, ruptured*/
        ,'I7132'        /*Juxtarenal abdominal aortic aneurysm, ruptured*/
        ,'I7133'        /*Infrarenal abdominal aortic aneurysm, ruptured*/
        ,'I7140'        /*Abdominal aortic aneurysm, without rupture, unspecified*/
        ,'I7141'        /*Pararenal abdominal aortic aneurysm, without rupture*/
        ,'I7142'        /*Juxtarenal abdominal aortic aneurysm, without rupture*/
        ,'I7143'        /*Infrarenal abdominal aortic aneurysm, without rupture*/
        ,'I7150'        /*Thoracoabdominal aortic aneurysm, ruptured, unspecified*/
        ,'I7151'        /*Supraceliac aneurysm of the thoracoabdominal aorta, ruptured*/
        ,'I7152'        /*Paravisceral aneurysm of the thoracoabdominal aorta, ruptured*/
        ,'I7160'        /*Thoracoabdominal aortic aneurysm, without rupture, unspecified*/
        ,'I7161'        /*Supraceliac aneurysm of the thoracoabdominal aorta, without rupture*/
        ,'I7162'        /*Paravisceral aneurysm of the thoracoabdominal aorta, without rupture*/
        ,'I7102'                /*Dissection of abdominal aorta*/
        ,'I7103'                /*Dissection of thoracoabdominal aorta*/
        ,'I711'                 /*Thoracic aortic aneurysm, ruptured*/
        ,'I712'                 /*Thoracic aortic aneurysm, without rupture*/
        ,'I713'                 /*Abdominal aortic aneurysm, ruptured*/
        ,'I714'                 /*Abdominal aortic aneurysm, without rupture*/
        ,'I715'                 /*Thoracoabdominal aortic aneurysm, ruptured*/
        ,'I716'                 /*Thoracoabdominal aortic aneurysm, without rupture*/
        ,'I718'                 /*Aortic aneurysm of unspecified site, ruptured*/
        ,'I719'                 /*Aortic aneurysm of unspecified site, without rupture*/
        ,'I790' = '1'           /*Aneurysm of aorta in diseases classified elsewhere*/
        OTHER = '0';

    /* 3. Acute renal failure ICD-10 DX*/
    Value $DX_Acute_Renal_Fail
        'N170'                 /*Acute kidney failure with tubular necrosis */                                                                                                                                                                                                                    
        ,'N171'                /*Acute kidney failure with acute cortical necrosis */                                                                                                                                                   
        ,'N172'                /*Acute kidney failure with medullary necrosis */                                                                                                                                                                                                                   
        ,'N178'                /*Other acute kidney failure */                                                                                                                                                                                                                                     
        ,'N179'                /*Acute kidney failure, unspecified */                                                                                                                                                                                                                              
        ,'O904'            /*Postpartum acute kidney failure*/
        ,'O9041'               /*Hepatorenal syndrome following labor and delivery*/
        ,'O9049' = '1'         /*Other postpartum acute kidney failure*/
        OTHER = '0';

    /*4. Adult respiratory distress syndrome DX*/
    Value $DX_Acute_Resp_Distress
        'J80'                    /*Acute respiratory distress syndrome*/
        ,'J951'                  /*Acute pulmonary insufficiency following thoracic surgery*/
        ,'J952'                  /*Acute pulmonary insufficiency following nonthoracic surgery*/
        ,'J953'                  /*Chronic pulmonary insufficiency following surgery*/
        ,'J95821'                /*Acute postprocedural respiratory failure*/
        ,'J95822'                /*Acute and chronic postprocedural respiratory failure*/
        ,'J9600'                 /*Acute respiratory failure, unspecified whether with hypoxia or hypercapnia*/
        ,'J9601'                 /*Acute respiratory failure with hypoxia*/
        ,'J9602'                 /*Acute respiratory failure with hypercapnia*/
        ,'J9620'                 /*Acute and chronic respiratory failure, unspecified whether with hypoxia or hypercapnia*/
        ,'J9621'                 /*Acute and chronic respiratory failure with hypoxia*/
        ,'J9622'                 /*Acute and chronic respiratory failure with hypercapnia*/
        ,'J9690'                 /*Respiratory failure, unspecified, unspecified whether with hypoxia or hypercapnia*/
        ,'J9691'                 /*Respiratory failure, unspecified with hypoxia*/
        ,'J9692'                 /*Respiratory failure, unspecified with hypercapnia*/
        ,'R0603'                 /*Acute respiratory distress*/
        ,'R092' = '1'            /*Respiratory arrest*/
        OTHER = '0';

    /*5. Amniotic fluid embolism IDC-10 DX*/
    Value $DX_Amniotic_Fluid_Emb
         'O88112'                 /*Amniotic fluid embolism in pregnancy, second trimester*/
        ,'O88113'                 /*Amniotic fluid embolism in pregnancy, third trimester*/
        ,'O88119'                 /*Amniotic fluid embolism in pregnancy, unspecified trimester*/
        ,'O8812'                  /*Amniotic fluid embolism in childbirth*/
        ,'O8813' = '1'            /*Amniotic fluid embolism in the puerperium*/
        OTHER = '0';

    /* 6. Cardiac arrest/ventricular fibrillation*/
    Value $DX_Card_Arrest_Vent_Fib
        'I462'                  /*Cardiac arrest due to underlying cardiac condition*/
        ,'I468'                 /*Cardiac arrest due to other underlying condition*/
        ,'I469'                 /*Cardiac arrest, cause unspecified*/
        ,'I4901'                /*Ventricular fibrillation*/
        ,'I4902' = '1'          /*Ventricular flutter*/
        OTHER = '0';

    /* 7. Conversion of cardiac rhythm PR */
    Value $PR_Conv_Cardiac_Rhythm
        '5A12012'               /*Performance of Cardiac Output, Single, Manual*/
        ,'5A2204Z' = '1'        /*Restoration of Cardiac Rhythm, Single*/
        OTHER = '0' ;

    /* 8.1 Disseminated intravascular coagulation */
    Value $DX_Diss_Intravasc_Coagul
        'D65'                     /*Disseminated intravascular coagulation [defibrination syndrome]*/
        ,'D688'                   /*Other specified coagulation defects*/
        ,'D689'                   /*Coagulation defect, unspecified*/
        ,'O45002'                 /*Premature separation of placenta with coagulation defect, unspecified, second trimester*/
        ,'O45003'                 /*Premature separation of placenta with coagulation defect, unspecified, third trimester*/
        ,'O45009'                 /*Premature separation of placenta with coagulation defect, unspecified, unspecified trimester*/
        ,'O45012'                 /*Premature separation of placenta with afibrinogenemia, second trimester*/
        ,'O45013'                 /*Premature separation of placenta with afibrinogenemia, third trimester*/
        ,'O45019'                 /*Premature separation of placenta with afibrinogenemia, unspecified trimester*/
        ,'O45022'                 /*Premature separation of placenta with disseminated intravascular coagulation, second trimester*/
        ,'O45023'                 /*Premature separation of placenta with disseminated intravascular coagulation, third trimester*/
        ,'O45029'                 /*Premature separation of placenta with disseminated intravascular coagulation, unspecified trimester*/
        ,'O45092'                 /*Premature separation of placenta with other coagulation defect, second trimester*/
        ,'O45093'                 /*Premature separation of placenta with other coagulation defect, third trimester*/
        ,'O45099'                 /*Premature separation of placenta with other coagulation defect, unspecified trimester*/
        ,'O46002'                 /*Antepartum hemorrhage with coagulation defect, unspecified, second trimester*/
        ,'O46003'                 /*Antepartum hemorrhage with coagulation defect, unspecified, third trimester*/
        ,'O46009'                 /*Antepartum hemorrhage with coagulation defect, unspecified, unspecified trimester*/
        ,'O46012'                 /*Antepartum hemorrhage with afibrinogenemia, second trimester*/
        ,'O46013'                 /*Antepartum hemorrhage with afibrinogenemia, third trimester*/
        ,'O46019'                 /*Antepartum hemorrhage with afibrinogenemia, unspecified trimester*/
        ,'O46022'                 /*Antepartum hemorrhage with disseminated intravascular coagulation, second trimester*/
        ,'O46023'                 /*Antepartum hemorrhage with disseminated intravascular coagulation, third trimester*/
        ,'O46029'                 /*Antepartum hemorrhage with disseminated intravascular coagulation, unspecified trimester*/
        ,'O46092'                 /*Antepartum hemorrhage with other coagulation defect, second trimester*/
        ,'O46093'                 /*Antepartum hemorrhage with other coagulation defect, third trimester*/
        ,'O46099'                 /*Antepartum hemorrhage with other coagulation defect, unspecified trimester*/
        ,'O670'                   /*Intrapartum hemorrhage with coagulation defect*/
        ,'O723' = '1'             /*Postpartum coagulation defects*/
        OTHER = '0';


    /* 8.2  Refined Disseminated intravascular coagulation (-O723, D68.8, D68.9) */
    Value $DX_Diss_Intravasc_Coagul3_
        'D65'                     /*Disseminated intravascular coagulation [defibrination syndrome]*/
        ,'O45002'                 /*Premature separation of placenta with coagulation defect, unspecified, second trimester*/
        ,'O45003'                 /*Premature separation of placenta with coagulation defect, unspecified, third trimester*/
        ,'O45009'                 /*Premature separation of placenta with coagulation defect, unspecified, unspecified trimester*/
        ,'O45012'                 /*Premature separation of placenta with afibrinogenemia, second trimester*/
        ,'O45013'                 /*Premature separation of placenta with afibrinogenemia, third trimester*/
        ,'O45019'                 /*Premature separation of placenta with afibrinogenemia, unspecified trimester*/
        ,'O45022'                 /*Premature separation of placenta with disseminated intravascular coagulation, second trimester*/
        ,'O45023'                 /*Premature separation of placenta with disseminated intravascular coagulation, third trimester*/
        ,'O45029'                 /*Premature separation of placenta with disseminated intravascular coagulation, unspecified trimester*/
        ,'O45092'                 /*Premature separation of placenta with other coagulation defect, second trimester*/
        ,'O45093'                 /*Premature separation of placenta with other coagulation defect, third trimester*/
        ,'O45099'                 /*Premature separation of placenta with other coagulation defect, unspecified trimester*/
        ,'O46002'                 /*Antepartum hemorrhage with coagulation defect, unspecified, second trimester*/
        ,'O46003'                 /*Antepartum hemorrhage with coagulation defect, unspecified, third trimester*/
        ,'O46009'                 /*Antepartum hemorrhage with coagulation defect, unspecified, unspecified trimester*/
        ,'O46012'                 /*Antepartum hemorrhage with afibrinogenemia, second trimester*/
        ,'O46013'                 /*Antepartum hemorrhage with afibrinogenemia, third trimester*/
        ,'O46019'                 /*Antepartum hemorrhage with afibrinogenemia, unspecified trimester*/
        ,'O46022'                 /*Antepartum hemorrhage with disseminated intravascular coagulation, second trimester*/
        ,'O46023'                 /*Antepartum hemorrhage with disseminated intravascular coagulation, third trimester*/
        ,'O46029'                 /*Antepartum hemorrhage with disseminated intravascular coagulation, unspecified trimester*/
        ,'O46092'                 /*Antepartum hemorrhage with other coagulation defect, second trimester*/
        ,'O46093'                 /*Antepartum hemorrhage with other coagulation defect, third trimester*/
        ,'O46099'                 /*Antepartum hemorrhage with other coagulation defect, unspecified trimester*/
        ,'O670' = '1'                  /*Intrapartum hemorrhage with coagulation defect*/
        OTHER = '0';

    /* 9. Eclampsia */
    Value $DX_Eclampsia
        'O1500'                 /*Eclampsia complicating pregnancy, unspecified trimester*/
        ,'O1502'                /*Eclampsia complicating pregnancy, second trimester*/
        ,'O1503'                /*Eclampsia complicating pregnancy, third trimester*/
        ,'O151'                 /*Eclampsia complicating labor*/
        ,'O152'                 /*Eclampsia complicating the puerperium*/
        ,'O159' = '1'           /*Eclampsia, unspecified as to time period*/
        OTHER = '0';

    /* 10. Heart failure/arrest during surgery or procedure */
    Value $DX_Heart_Fail_Surgery
        'I97120'                  /*Postprocedural cardiac arrest following cardiac surgery*/
        ,'I97121'                 /*Postprocedural cardiac arrest following other surgery*/
        ,'I97130'                 /*Postprocedural heart failure following cardiac surgery*/
        ,'I97131'                 /*Postprocedural heart failure following other surgery*/
        ,'I97710'                 /*Intraoperative cardiac arrest during cardiac surgery*/
        ,'I97711'='1'             /*Intraoperative cardiac arrest during other surgery*/
        OTHER = '0';

    /* 11. Puerperal cerebrovascular disorders */
    Value $DX_Puerp_Cerebrovascular
        'A812'      /*Progressive multifocal leukoencephalopathy*/
        ,'G450'     /*Vertebro-basilar artery syndrome*/
        ,'G451'     /*Carotid artery syndrome (hemispheric)*/
        ,'G452'     /*Multiple and bilateral precerebral artery syndromes*/
        ,'G453'     /*Amaurosis fugax*/
        ,'G454'     /*Transient global amnesia*/
        ,'G458'     /*Oth transient cerebral ischemic attacks and related synd*/
        ,'G459'     /*Transient cerebral ischemic attack, unspecified*/
        ,'G460'     /*Middle cerebral artery syndrome*/
        ,'G461'     /*Anterior cerebral artery syndrome*/
        ,'G462'     /*Posterior cerebral artery syndrome*/
        ,'G463'     /*Brain stem stroke syndrome*/
        ,'G464'     /*Cerebellar stroke syndrome*/
        ,'G465'     /*Pure motor lacunar syndrome*/
        ,'G466'     /*Pure sensory lacunar syndrome*/
        ,'G467'     /*Other lacunar syndromes*/
        ,'G468'     /*Oth vascular syndromes of brain in cerebrovascular diseases*/
        ,'G9349'     /*Other encephalopathy*/
        ,'H3400'     /*Transient retinal artery occlusion, unspecified eye*/
        ,'H3401'     /*Transient retinal artery occlusion, right eye*/
        ,'H3402'     /*Transient retinal artery occlusion, left eye*/
        ,'H3403'     /*Transient retinal artery occlusion, bilateral*/
        ,'I6000'     /*Ntrm subarach hemorrhage from unsp carotid siphon and bifurc*/
        ,'I6001'     /*Ntrm subarach hemor from right carotid siphon and bifurc*/
        ,'I6002'     /*Ntrm subarach hemorrhage from left carotid siphon and bifurc*/
        ,'I6010'     /*Ntrm subarach hemorrhage from unsp middle cerebral artery*/
        ,'I6011'     /*Ntrm subarach hemorrhage from right middle cerebral artery*/
        ,'I6012'     /*Ntrm subarach hemorrhage from left middle cerebral artery*/
        ,'I602'      /*Ntrm subarach hemorrhage from anterior communicating artery*/
        ,'I6020'     /*Ntrm subarach hemor from unsp anterior communicating artery*/
        ,'I6021'     /*Ntrm subarach hemor from right anterior communicating artery*/
        ,'I6022'     /*Ntrm subarach hemor from left anterior communicating artery*/
        ,'I6030'     /*Ntrm subarach hemor from unsp posterior communicating artery*/
        ,'I6031'     /*Ntrm subarach hemor from right post communicating artery*/
        ,'I6032'     /*Ntrm subarach hemor from left posterior communicating artery*/
        ,'I604'      /*Nontraumatic subarachnoid hemorrhage from basilar artery*/
        ,'I6050'     /*Nontraumatic subarachnoid hemorrhage from unsp verteb art*/
        ,'I6051'     /*Nontraumatic subarachnoid hemorrhage from r verteb art*/
        ,'I6052'     /*Nontraumatic subarachnoid hemorrhage from l verteb art*/
        ,'I606'      /*Nontraumatic subarachnoid hemorrhage from oth intracran art*/
        ,'I607'      /*Nontraumatic subarachnoid hemorrhage from unsp intracran art*/
        ,'I608'      /*Other nontraumatic subarachnoid hemorrhage*/
        ,'I609'      /*Nontraumatic subarachnoid hemorrhage, unspecified*/
        ,'I610'      /*Nontraumatic intcrbl hemorrhage in hemisphere, subcortical*/
        ,'I611'      /*Nontraumatic intcrbl hemorrhage in hemisphere, cortical*/
        ,'I612'      /*Nontraumatic intracerebral hemorrhage in hemisphere, unsp*/
        ,'I613'      /*Nontraumatic intracerebral hemorrhage in brain stem*/
        ,'I614'      /*Nontraumatic intracerebral hemorrhage in cerebellum*/
        ,'I615'      /*Nontraumatic intracerebral hemorrhage, intraventricular*/
        ,'I616'      /*Nontraumatic intracerebral hemorrhage, multiple localized*/
        ,'I618'      /*Other nontraumatic intracerebral hemorrhage*/
        ,'I619'      /*Nontraumatic intracerebral hemorrhage, unspecified*/
        ,'I6200'     /*Nontraumatic subdural hemorrhage, unspecified*/
        ,'I6201'     /*Nontraumatic acute subdural hemorrhage*/
        ,'I6202'     /*Nontraumatic subacute subdural hemorrhage*/
        ,'I6203'     /*Nontraumatic chronic subdural hemorrhage*/
        ,'I621'      /*Nontraumatic extradural hemorrhage*/
        ,'I629'      /*Nontraumatic intracranial hemorrhage, unspecified*/
        ,'I6300'     /*Cerebral infarction due to thombos unsp precerebral artery*/
        ,'I63011'    /*Cerebral infarction due to thrombosis of r verteb art*/
        ,'I63012'    /*Cerebral infarction due to thrombosis of l verteb art*/
        ,'I63013'    /*Cerebral infrc due to thrombosis of bilateral verteb art*/
        ,'I63019'    /*Cerebral infarction due to thombos unsp vertebral artery*/
        ,'I6302'     /*Cerebral infarction due to thrombosis of basilar artery*/
        ,'I63031'    /*Cerebral infrc due to thrombosis of right carotid artery*/
        ,'I63032'    /*Cerebral infarction due to thrombosis of left carotid artery*/
        ,'I63033'    /*Cerebral infrc due to thombos of bilateral carotid arteries*/
        ,'I63039'    /*Cerebral infarction due to thrombosis of unsp carotid artery*/
        ,'I6309'     /*Cerebral infarction due to thrombosis of precerebral artery*/
        ,'I6310'     /*Cerebral infarction due to embolism of unsp precerb artery*/
        ,'I63111'    /*Cerebral infarction due to embolism of r verteb art*/
        ,'I63112'    /*Cerebral infarction due to embolism of left vertebral artery*/
        ,'I63113'    /*Cerebral infarction due to embolism of unsp vertebral artery*/
        ,'I63119'    /*Cerebral infarction due to embolism of unsp vertebral artery*/
        ,'I6312'     /*Cerebral infarction due to embolism of basilar artery*/
        ,'I63131'    /*Cerebral infarction due to embolism of right carotid artery*/
        ,'I63132'    /*Cerebral infarction due to embolism of left carotid artery*/
        ,'I63133'    /*Cerebral infrc due to embolism of bilateral carotid arteries*/
        ,'I63139'    /*Cerebral infarction due to embolism of unsp carotid artery*/
        ,'I6319'     /*Cerebral infarction due to embolism of precerebral artery*/
        ,'I6320'     /*Cereb infrc due to unsp occls or stenos of unsp precerb art*/
        ,'I63211'    /*Cereb infrc due to unsp occls or stenos of right verteb art*/
        ,'I63212'    /*Cereb infrc due to unsp occls or stenosis of left verteb art*/
        ,'I63213'    /*Cereb infrc due to unsp occls or stenosis of bi verteb art*/
        ,'I63219'    /*Cereb infrc due to unsp occls or stenosis of unsp verteb art*/
        ,'I6322'     /*Cerebral infrc due to unsp occls or stenosis of basilar art*/
        ,'I63231'    /*Cereb infrc due to unsp occls or stenos of right carotid art*/
        ,'I63232'    /*Cereb infrc due to unsp occls or stenos of left carotid art*/
        ,'I63233'    /*Cereb infrc due to unsp occls or stenosis of bi carotid art*/
        ,'I63239'    /*Cereb infrc due to unsp occls or stenos of unsp crtd artery*/
        ,'I6329'     /*Cerebral infrc due to unsp occls or stenosis of precerb art*/
        ,'I6330'     /*Cerebral infarction due to thombos unsp cerebral artery*/
        ,'I63311'    /*Cereb infrc due to thombos of right middle cerebral artery*/
        ,'I63312'    /*Cerebral infrc due to thombos of left middle cerebral artery*/
        ,'I63313'    /*Cerebral infrc due to thombos of bi middle cerebral arteries*/
        ,'I63319'    /*Cerebral infrc due to thombos unsp middle cerebral artery*/
        ,'I63321'    /*Cerebral infrc due to thombos of right ant cerebral artery*/
        ,'I63322'    /*Cerebral infrc due to thombos of left ant cerebral artery*/
        ,'I63323'    /*Cerebral infrc due to thombos of bilateral ant cerebral arteries*/
        ,'I63329'    /*Cerebral infrc due to thombos unsp anterior cerebral artery*/
        ,'I63331'    /*Cerebral infrc due to thombos of right post cerebral artery*/
        ,'I63332'    /*Cerebral infrc due to thombos of left post cerebral artery*/
        ,'I63333'    /*Cerebral infrc due to thombos of bi post cerebral arteries*/
        ,'I63339'    /*Cerebral infrc due to thombos unsp posterior cerebral artery*/
        ,'I63341'    /*Cerebral infrc due to thrombosis of right cereblr artery*/
        ,'I63342'    /*Cerebral infarction due to thrombosis of left cereblr artery*/
        ,'I63343'    /*Cerebral infrc due to thombos of bilateral cereblr arteries*/
        ,'I63349'    /*Cerebral infarction due to thombos unsp cerebellar artery*/
        ,'I6339'     /*Cerebral infarction due to thrombosis of oth cerebral artery*/
        ,'I6340'     /*Cerebral infarction due to embolism of unsp cerebral artery*/
        ,'I63411'    /*Cereb infrc due to embolism of right middle cerebral artery*/
        ,'I63412'    /*Cereb infrc due to embolism of left middle cerebral artery*/
        ,'I63413'    /*Cerebral infrc due to embolism of bi middle cerebral art*/
        ,'I63419'    /*Cereb infrc due to embolism of unsp middle cerebral artery*/
        ,'I63421'    /*Cerebral infrc due to embolism of right ant cerebral artery*/
        ,'I63422'    /*Cerebral infrc due to embolism of left ant cerebral artery*/
        ,'I63423'    /*Cerebral infrc due to embolism of bi ant cerebral arteries*/
        ,'I63429'    /*Cerebral infrc due to embolism of unsp ant cerebral artery*/
        ,'I63431'    /*Cerebral infrc due to embolism of right post cerebral artery*/
        ,'I63432'    /*Cerebral infrc due to embolism of left post cerebral artery*/
        ,'I63433'    /*Cerebral infrc due to embolism of bi post cerebral arteries*/
        ,'I63439'    /*Cerebral infrc due to embolism of unsp post cerebral artery*/
        ,'I63441'    /*Cerebral infarction due to embolism of right cereblr artery*/
        ,'I63442'    /*Cerebral infarction due to embolism of left cereblr artery*/
        ,'I63443'    /*Cerebral infrc due to embolism of bilateral cereblr arteries*/
        ,'I63449'    /*Cerebral infarction due to embolism of unsp cereblr artery*/
        ,'I6349'     /*Cerebral infarction due to embolism of other cerebral artery*/
        ,'I6350'     /*Cereb infrc due to unsp occls or stenos of unsp cereb artery*/
        ,'I63511'    /*Cereb infrc d/t unsp occls or stenos of right mid cereb art*/
        ,'I63512'    /*Cereb infrc d/t unsp occls or stenos of left mid cereb art*/
        ,'I63513'    /*Cereb infrc due to unsp occls or stenos of bi mid cereb art*/
        ,'I63519'    /*Cereb infrc d/t unsp occls or stenos of unsp mid cereb art*/
        ,'I63521'    /*Cereb infrc d/t unsp occls or stenos of right ant cereb art*/
        ,'I63522'    /*Cereb infrc d/t unsp occls or stenos of left ant cereb art*/
        ,'I63523'    /*Cerebral infrc due to unsp occls or stenos of bi ant cereb art*/
        ,'I63529'    /*Cereb infrc d/t unsp occls or stenos of unsp ant cereb art*/
        ,'I63531'    /*Cereb infrc d/t unsp occls or stenos of right post cereb art*/
        ,'I63532'    /*Cereb infrc d/t unsp occls or stenos of left post cereb art*/
        ,'I63533'    /*Cerebral infrc due to unsp occls or stenos of bi post cereb art*/
        ,'I63539'    /*Cereb infrc d/t unsp occls or stenos of unsp post cereb art*/
        ,'I63541'    /*Cereb infrc due to unsp occls or stenos of right cereblr art*/
        ,'I63542'    /*Cereb infrc due to unsp occls or stenos of left cereblr art*/
        ,'I63543'    /*Cereb infrc due to unsp occls or stenosis of bi cereblr art*/
        ,'I63549'    /*Cereb infrc due to unsp occls or stenos of unsp cereblr art*/
        ,'I6359'     /*Cereb infrc due to unsp occls or stenosis of cerebral artery*/
        ,'I636'      /*Cerebral infrc due to cerebral venous thombos, nonpyogenic*/
        ,'I638'      /*Other cerebral infarction*/
        ,'I6381'     /*Other cereb infrc due to occls or stenosis of small artery*/
        ,'I6389'     /*Other cerebral infarction*/
        ,'I639'      /*Cerebral infarction, unspecified*/
        ,'I6501'     /*Occlusion and stenosis of right vertebral artery*/
        ,'I6502'     /*Occlusion and stenosis of left vertebral artery*/
        ,'I6503'     /*Occlusion and stenosis of bilateral vertebral arteries*/
        ,'I6509'     /*Occlusion and stenosis of unspecified vertebral artery*/
        ,'I651'      /*Occlusion and stenosis of basilar artery*/
        ,'I6521'     /*Occlusion and stenosis of right carotid artery*/
        ,'I6522'     /*Occlusion and stenosis of left carotid artery*/
        ,'I6523'     /*Occlusion and stenosis of bilateral carotid arteries*/
        ,'I6529'     /*Occlusion and stenosis of unspecified carotid artery*/
        ,'I658'      /*Occlusion and stenosis of other precerebral arteries*/
        ,'I659'      /*Occlusion and stenosis of unspecified precerebral artery*/
        ,'I6601'     /*Occlusion and stenosis of right middle cerebral artery*/
        ,'I6602'     /*Occlusion and stenosis of left middle cerebral artery*/
        ,'I6603'     /*Occlusion and stenosis of bilateral middle cerebral arteries*/
        ,'I6609'     /*Occlusion and stenosis of unspecified middle cerebral artery*/
        ,'I6611'     /*Occlusion and stenosis of right anterior cerebral artery*/
        ,'I6612'     /*Occlusion and stenosis of left anterior cerebral artery*/
        ,'I6613'     /*Occlusion and stenosis of bi anterior cerebral arteries*/
        ,'I6619'     /*Occlusion and stenosis of unsp anterior cerebral artery*/
        ,'I6621'     /*Occlusion and stenosis of right posterior cerebral artery*/
        ,'I6622'     /*Occlusion and stenosis of left posterior cerebral artery*/
        ,'I6623'     /*Occlusion and stenosis of bi posterior cerebral arteries*/
        ,'I6629'     /*Occlusion and stenosis of unsp posterior cerebral artery*/
        ,'I663'      /*Occlusion and stenosis of cerebellar arteries*/
        ,'I668'      /*Occlusion and stenosis of other cerebral arteries*/
        ,'I669'      /*Occlusion and stenosis of unspecified cerebral artery*/
        ,'I670'      /*Dissection of cerebral arteries, nonruptured*/
        ,'I671'      /*Cerebral aneurysm, nonruptured*/
        ,'I672'      /*Cerebral atherosclerosis*/
        ,'I673'      /*Progressive vascular leukoencephalopathy*/
        ,'I674'      /*Hypertensive encephalopathy*/
        ,'I675'      /*Moyamoya disease*/
        ,'I676'      /*Nonpyogenic thrombosis of intracranial venous system*/
        ,'I677'      /*Cerebral arteritis, not elsewhere classified*/
        ,'I6781'     /*Acute cerebrovascular insufficiency*/
        ,'I6782'     /*Cerebral ischemia*/
        ,'I6783'     /*Posterior reversible encephalopathy syndrome*/
        ,'I67841'    /*Reversible cerebrovascular vasoconstriction syndrome*/
        ,'I67848'    /*Other cerebrovascular vasospasm and vasoconstriction*/
        ,'I67850'    /*Cereb autosom dom artopath w subcort infarcts & leukoenceph*/
        ,'I67858'    /*Other hereditary cerebrovascular disease*/
        ,'I6789'     /*Other cerebrovascular disease*/
        ,'I679'      /*Cerebrovascular disease, unspecified*/
        ,'I680'      /*Cerebral amyloid angiopathy*/
        ,'I682'      /*Cerebral arteritis in other diseases classified elsewhere*/
        ,'I688'      /*Oth cerebrovascular disorders in diseases classd elswhr*/
        ,'O2250'     /*Cerebral venous thrombosis in pregnancy, unsp trimester*/
        ,'O2252'     /*Cerebral venous thrombosis in pregnancy, second trimester*/
        ,'O2253'     /*Cerebral venous thrombosis in pregnancy, third trimester*/
        ,'I97810'    /*Intraoperative cerebvasc infarction during cardiac surgery*/
        ,'I97811'    /*Intraoperative cerebrovascular infarction during oth surgery*/
        ,'I97820'    /*Postprocedural cerebvasc infarction folowing cardiac surgery*/
        ,'I97821'    /*Postprocedural cerebrovascular infarction following oth surgery*/
        ,'O873' = '1'    /*Cerebral venous thrombosis in the puerperium*/
        OTHER = '0';

    /* 12. Pulmonary edema / Acute heart failure */
    Value $DX_Pulmonary_Edema
        'J810'                   /*Acute pulmonary edema*/
        ,'I501'                  /*Left ventricular failure, unspecified*/
        ,'I5020'                 /*Unspecified systolic (congestive) heart failure*/
        ,'I5021'                 /*Acute systolic (congestive) heart failure*/
        ,'I5023'                 /*Acute on chronic systolic (congestive) heart failure*/
        ,'I5030'                 /*Unspecified diastolic (congestive) heart failure*/
        ,'I5031'                 /*Acute diastolic (congestive) heart failure*/
        ,'I5033'                 /*Acute on chronic diastolic (congestive) heart failure*/
        ,'I5040'                 /*Unspecified combined systolic (congestive) and diastolic (congestive) heart failure*/
        ,'I5041'                 /*Acute combined systolic (congestive) and diastolic (congestive) heart failure*/
        ,'I5043'                 /*Acute on chronic combined systolic (congestive) and diastolic (congestive) heart failure*/
        ,'I50810'                /*Right heart failure, unspecified*/
        ,'I50811'                /*Acute right heart failure*/
        ,'I50813'                /*Acute on chronic right heart failure*/
        ,'I50814'                /*Right heart failure due to left heart failure*/
        ,'I5082'                 /*Biventricular heart failure*/
        ,'I5083'                 /*High output heart failure*/
        ,'I5084'                 /*End stage heart failure*/
        ,'I5089'                 /*Other heart failure*/
        ,'I509' = '1'            /*Heart failure, unspecified*/
        OTHER = '0';

    /* 13. Severe anesthesia complications */
    Value $DX_Severe_Anesth_Comp
        'O29112'                  /*Cardiac arrest due to anesthesia during pregnancy, second trimester*/
        ,'O29113'                 /*Cardiac arrest due to anesthesia during pregnancy, third trimester*/
        ,'O29119'                 /*Cardiac arrest due to anesthesia during pregnancy, unspecified trimester*/
        ,'O29122'                 /*Cardiac failure due to anesthesia during pregnancy, second trimester*/
        ,'O29123'                 /*Cardiac failure due to anesthesia during pregnancy, third trimester*/
        ,'O29129'                 /*Cardiac failure due to anesthesia during pregnancy, unspecified trimester*/
        ,'O29192'                 /*Other cardiac complications of anesthesia during pregnancy, second trimester*/
        ,'O29193'                 /*Other cardiac complications of anesthesia during pregnancy, third trimester*/
        ,'O29199'                 /*Other cardiac complications of anesthesia during pregnancy, unspecified trimester*/
        ,'O29212'                 /*Cerebral anoxia due to anesthesia during pregnancy, second trimester*/
        ,'O29213'                 /*Cerebral anoxia due to anesthesia during pregnancy, third trimester*/
        ,'O29219'                 /*Cerebral anoxia due to anesthesia during pregnancy, unspecified trimester*/
        ,'O29292'                 /*Other central nervous system complications of anesthesia during pregnancy, second trimester*/
        ,'O29293'                 /*Other central nervous system complications of anesthesia during pregnancy, third trimester*/
        ,'O29299'                 /*Other central nervous system complications of anesthesia during pregnancy, unspecified trimester*/
        ,'O740'                   /*Aspiration pneumonitis due to anesthesia during labor and delivery*/
        ,'O741'                   /*Other pulmonary complications of anesthesia during labor and delivery*/
        ,'O742'                   /*Cardiac complications of anesthesia during labor and delivery*/
        ,'O743'                   /*Central nervous system complications of anesthesia during labor and delivery*/
        ,'O8901'                  /*Aspiration pneumonitis due to anesthesia during the puerperium*/
        ,'O8909'                  /*Other pulmonary complications of anesthesia during the puerperium*/
        ,'O891'                   /*Cardiac complications of anesthesia during the puerperium*/
        ,'O892'                   /*Central nervous system complications of anesthesia during the puerperium*/
        ,'T882XXA'                /*Shock due to anesthesia, initial encounter*/
        ,'T883XXA'='1'            /*Malignant hyperthermia due to anesthesia, initial encounter*/
        OTHER = '0';

    /* 14. Sepsis */
    Value $DX_Sepsis
        'I76'                       /*Septic arterial embolism*/
        ,'O85'                      /*Puerperal sepsis*/
        ,'O8604'                    /*Sepsis following an obstetrical procedure*/
        ,'T8112XA'                  /*Postprocedural septic shock, initial encounter*/
        ,'T8144XA'                  /*Sepsis following a procedure, initial encounter*/
        ,'R6520'                    /*Severe sepsis without septic shock*/
        ,'R6521'                    /*Severe sepsis with septic shock*/
        ,'A400'                     /*Sepsis due to streptococcus, group A*/
        ,'A401'                     /*Sepsis due to streptococcus, group B*/
        ,'A403'                     /*Sepsis due to Streptococcus pneumoniae*/
        ,'A408'                     /*Other streptococcal sepsis*/
        ,'A409'                     /*Streptococcal sepsis, unspecified*/
        ,'A4101'                    /*Sepsis due to Methicillin susceptible Staphylococcus aureus*/
        ,'A4102'                    /*Sepsis due to Methicillin resistant Staphylococcus aureus*/
        ,'A411'                     /*Sepsis due to other specified staphylococcus*/
        ,'A412'                     /*Sepsis due to unspecified staphylococcus*/
        ,'A413'                     /*Sepsis due to Hemophilus influenzae*/
        ,'A414'                     /*Sepsis due to anaerobes*/
        ,'A4150'                    /*Gram-negative sepsis, unspecified*/
        ,'A4151'                    /*Sepsis due to Escherichia coli [E. coli]*/
        ,'A4152'                    /*Sepsis due to Pseudomonas*/
        ,'A4153'                    /*Sepsis due to Serratia*/
        ,'A4154'                    /*Sepsis due to Acinetobacter baumannii*/
        ,'A4159'                    /*Other Gram-negative sepsis*/
        ,'A4181'                    /*Sepsis due to Enterococcus*/
        ,'A4189'                    /*Other specified sepsis*/
        ,'A419'                     /*Sepsis, unspecified organism*/
        ,'A327' = '1'               /*Listerial sepsis*/
        OTHER = '0';

    /* 15. Shock */
    value $DX_Shock
        'O751'                      /*Shock during or following labor and delivery*/
        ,'R570'                     /*Cardiogenic shock*/
        ,'R571'                     /*Hypovolemic shock*/
        ,'R578'                     /*Other shock*/
        ,'R579'                     /*Shock, unspecified*/
        ,'T782XXA'                  /*Anaphylactic shock, unspecified, initial encounter*/
        ,'T886XXA'                  /*Anaphylactic reaction due to adverse effect of correct drug or medicament properly administered, initial encounter*/
        ,'T8110XA'                  /*Postprocedural shock unspecified, initial encounter*/
        ,'T8111XA'                  /*Postprocedural cardiogenic shock, initial encounter*/
        ,'T8119XA' = '1'            /*Other postprocedural shock, initial encounter*/
        OTHER = '0';

    /* 16. Sickle cell disease with crisis */
    value $DX_Sickle_Cell_Crisis
        'D5700'                   /*Hb-SS disease with crisis, unspecified*/
        ,'D5701'                  /*Hb-SS disease with acute chest syndrome*/
        ,'D5702'                  /*Hb-SS disease with splenic sequestration*/
        ,'D5703'                  /*Hb-SS disease with cerebral vascular involvement*/
        ,'D5704'                  /*Hb-SS disease with dactylitis*/
        ,'D5709'                  /*Hb-SS disease with crisis with other specified complication*/
        ,'D57211'                 /*Sickle-cell/Hb-C disease with acute chest syndrome*/
        ,'D57212'                 /*Sickle-cell/Hb-C disease with splenic sequestration*/
        ,'D57219'                 /*Sickle-cell/Hb-C disease with crisis, unspecified*/
        ,'D57411'                 /*Sickle-cell thalassemia, unspecified, with acute chest syndrome*/
        ,'D57412'                 /*Sickle-cell thalassemia, unspecified, with splenic sequestration*/
        ,'D57419'                 /*Sickle-cell thalassemia, unspecified, with crisis*/
        ,'D57213'                 /*Sickle-cell/Hb-C disease with cerebral vascular involvement*/
        ,'D57214'                 /*Sickle-cell/Hb-C disease with dactylitis*/
        ,'D57218'                 /*Sickle-cell/Hb-C disease with crisis with other specified complication*/
        ,'D57413'                 /*Sickle-cell thalassemia, unspecified, with cerebral vascular involvement*/
        ,'D57414'                 /*Sickle-cell thalassemia, unspecified, with dactylitis*/
        ,'D57418'                 /*Sickle-cell thalassemia, unspecified, with crisis with other specified complication*/
        ,'D57431'                 /*Sickle-cell thalassemia beta zero with acute chest syndrome*/
        ,'D57432'                 /*Sickle-cell thalassemia beta zero with splenic sequestration*/
        ,'D57433'                 /*Sickle-cell thalassemia beta zero with cerebral vascular involvement*/
        ,'D57434'                 /*Sickle-cell thalassemia beta zero with dactylitis*/
        ,'D57438'                 /*Sickle-cell thalassemia beta zero with crisis with other specified complication*/
        ,'D57439'                 /*Sickle-cell thalassemia beta zero with crisis, unspecified*/
        ,'D57451'                 /*Sickle-cell thalassemia beta plus with acute chest syndrome*/
        ,'D57452'                 /*Sickle-cell thalassemia beta plus with splenic sequestration*/
        ,'D57453'                 /*Sickle-cell thalassemia beta plus with cerebral vascular involvement*/
        ,'D57454'                 /*Sickle-cell thalassemia beta plus with dactylitis*/
        ,'D57458'                 /*Sickle-cell thalassemia beta plus with crisis with other specified complication*/
        ,'D57459'                 /*Sickle-cell thalassemia beta plus with crisis, unspecified*/
        ,'D57811'                 /*Other sickle-cell disorders with acute chest syndrome*/
        ,'D57812'                 /*Other sickle-cell disorders with splenic sequestration*/
        ,'D57813'                 /*Other sickle-cell disorders with cerebral vascular involvement*/
        ,'D57814'                 /*Other sickle-cell disorders with dactylitis*/
        ,'D57818'                 /*Other sickle-cell disorders with crisis with other specified complication*/
        ,'D57819' = '1'           /*Other sickle-cell disorders with crisis, unspecified*/
        OTHER = '0';

    /*17. Air and thrombotic embolism*/
    value $DX_Air_Thrombotic_Embolism
        'I2601'                  /*Septic pulmonary embolism with acute cor pulmonale*/
        ,'I2602'                 /*Saddle embolus of pulmonary artery with acute cor pulmonale*/
        ,'I2609'                 /*Other pulmonary embolism with acute cor pulmonale*/
        ,'I2690'                 /*Septic pulmonary embolism without acute cor pulmonale*/
        ,'I2692'                 /*Saddle embolus of pulmonary artery without acute cor pulmonale*/
        ,'I2693'                 /*Single subsegmental pulmonary embolism without acute cor pulmonale*/
        ,'I2694'                 /*Multiple subsegmental pulmonary emboli without acute cor pulmonale*/
        ,'I2699'                 /*Other pulmonary embolism without acute cor pulmonale*/
        ,'O88012'                /*Air embolism in pregnancy, second trimester*/
        ,'O88013'                /*Air embolism in pregnancy, third trimester*/
        ,'O88019'                /*Air embolism in pregnancy, unspecified trimester*/
        ,'O8802'                 /*Air embolism in childbirth*/
        ,'O8803'                 /*Air embolism in the puerperium*/
        ,'O88212'                /*Thromboembolism in pregnancy, second trimester*/
        ,'O88213'                /*Thromboembolism in pregnancy, third trimester*/
        ,'O88219'                /*Thromboembolism in pregnancy, unspecified trimester*/
        ,'O8822'                 /*Thromboembolism in childbirth*/
        ,'O8823'                 /*Thromboembolism in the puerperium*/
        ,'O88312'                /*Pyemic and septic embolism in pregnancy, second trimester*/
        ,'O88313'                /*Pyemic and septic embolism in pregnancy, third trimester*/
        ,'O88319'                /*Pyemic and septic embolism in pregnancy, unspecified trimester*/
        ,'O8832'                 /*Pyemic and septic embolism in childbirth*/
        ,'O8833'                 /*Pyemic and septic embolism in the puerperium*/
        ,'O88812'                /*Other embolism in pregnancy, second trimester*/
        ,'O88813'                /*Other embolism in pregnancy, third trimester*/
        ,'O88819'                /*Other embolism in pregnancy, unspecified trimester*/
        ,'O8882'                 /*Other embolism in childbirth*/
        ,'O8883'                 /*Other embolism in the puerperium*/
        ,'T800XXA' = '1'         /*Air embolism following infusion, transfusion and therapeutic injection, initial encounter*/
        OTHER = '0';

    /* 18. Hysterectomy */
    Value $PR_Hysterectomy
        '0UT90ZL'           /*Resection of Uterus, Supracervical, Open Approach */
        ,'0UT90ZZ'          /*Resection of Uterus, Open Approach */
        ,'0UT97ZL'          /*Resection of Uterus, Supracervical, Via Natural or Artificial Opening */
        ,'0UT97ZZ' = '1'    /*Resection of Uterus, Via Natural or Artificial Opening */
        OTHER = '0';

    /* 19. Temporary tracheostomy */
    value $PR_Temp_Tracheostomy
        '0B110F4'           /*Bypass Trachea to Cutaneous with Tracheostomy Device, Open Approach*/
        ,'0B113F4'          /*Bypass Trachea to Cutaneous with Tracheostomy Device, Percutaneous Approach*/
        ,'0B114F4'  = '1'   /*Bypass Trachea to Cutaneous with Tracheostomy Device, Percutaneous Endoscopic Approach*/
        OTHER = '0';

    /* 20.Ventilation */
    value $PR_Ventilation
        '5A1935Z'           /* Ventilation, Less than 24 Consecutive Hours*/
        ,'5A1945Z'          /* Ventilation, 24-96 Consecutive Hours*/
        ,'5A1955Z' = '1'    /* Ventilation, Greater than 96 Consecutive Hours*/ 
        OTHER = '0';

/* FORMAT FOR Dialysis procedure codes */
    Value $DIALYIP
        '3E1M39Z' /*Irrigation of Peritoneal Cavity using Dialysate, Percutaneous Approach */
        ,'5A1D00Z' /*Performance of Urinary Filtration, Single */ /*Code expires FY2025 */
        ,'5A1D60Z' /*Performance of Urinary Filtration, Multiple */ /*Code expires FY2025 */
        ,'5A1D70Z' /*Performance of Urinary Filtration, Intermittent, Less than 6 Hours Per Day */
        ,'5A1D80Z' /*Performance of Urinary Filtration, Prolonged Intermittent, 6-18 hours Per Day */
        ,'5A1D90Z' = '1' /*Performance of Urinary Filtration, Continuous, Greater than 18 hours Per Day */
        OTHER = '0';

/* Delivery codes */

    /*ICD-10 Delivery DX */
    value $DX_Delivery
        "Z370" = '1' /*Single live birth */
        "Z371" = '1' /*Single stillbirth */
        "Z372" = '1' /*Twins, both liveborn */
        "Z373" = '1' /*Twins, one liveborn and one stillborn */
        "Z374" = '1' /*Twins, both stillborn */
        "Z3750" = '1' /*Multiple births, unspecified, all liveborn */
        "Z3751" = '1' /*Triplets, all liveborn */
        "Z3752" = '1' /*Quadruplets, all liveborn */
        "Z3753" = '1' /*Quintuplets, all liveborn */
        "Z3754" = '1' /*Sextuplets, all liveborn */
        "Z3759" = '1' /*Other multiple births, all liveborn */
        "Z3760" = '1' /*Multiple births, unspecified, some liveborn */
        "Z3761" = '1' /*Triplets, some liveborn */
        "Z3762" = '1' /*Quadruplets, some liveborn */
        "Z3763" = '1' /*Quintuplets, some liveborn */
        "Z3764" = '1' /*Sextuplets, some liveborn */
        "Z3769" = '1' /*Other multiple births, some liveborn */
        "Z377" = '1' /*Other multiple births, all stillborn */
        "Z379" = '1' /*Outcome of delivery, unspecified */
        "O80" = '1' /*Encounter for full-term uncomplicated delivery*/
        "O82" = '1' /*Encounter for cesarean delivery without indication*/
        "O7582" = '1' /*Onset (spontaneous) of labor after 37 completed weeks of gestation but before 39 completed weeks gestation, with delivery by (planned) cesarean section */
        OTHER = '0';

    /*Delivery ICD-10 procedure codes*/
    value $PR_Delivery
        "10D00Z0" = '1'      /*Extraction of Products of Conception, High, Open Approach*/
        "10D00Z1" = '1'      /*Extraction of Products of Conception, Low, Open Approach*/
        "10D00Z2" = '1'      /*Extraction of Products of Conception, Extraperitoneal, Open Approach*/
        "10D07Z3" = '1'      /*Extraction of Products of Conception, Low Forceps, Via Natural or Artificial Opening*/
        "10D07Z4" = '1'      /*Extraction of Products of Conception, Mid Forceps, Via Natural or Artificial Opening*/
        "10D07Z5" = '1'      /*Extraction of Products of Conception, High Forceps, Via Natural or Artificial Opening*/
        "10D07Z6" = '1'      /*Extraction of Products of Conception, Vacuum, Via Natural or Artificial Opening*/
        "10D07Z7" = '1'      /*Extraction of Products of Conception, Internal Version, Via Natural or Artificial Opening*/
        "10D07Z8" = '1'      /*Extraction of Products of Conception, Other, Via Natural or Artificial Opening*/
        "10E0XZZ" = '1'      /*Delivery of Products of Conception, External Approach*/
        OTHER = '0';
    

  /* Abortion Codes */
    value $DX_Abortion
        "O000" = "1"        /*Abdominal pregnancy*/
        "O0000" = "1"       /*Abdominal pregnancy without intrauterine pregnancy*/
        "O0001" = "1"       /*Abdominal pregnancy with intrauterine pregnancy*/
        "O001" = "1"        /*Tubal pregnancy*/
        "O0010" = "1"       /*Tubal pregnancy without intrauterine pregnancy*/
        "O00101" = "1"      /*Right tubal pregnancy without intrauterine pregnancy*/
        "O00102" = "1"      /*Left tubal pregnancy without intrauterine pregnancy*/
        "O00109" = "1"      /*Unspecified tubal pregnancy without intrauterine pregnancy*/
        "O0011" = "1"       /*Tubal pregnancy with intrauterine pregnancy*/
        "O00111" = "1"      /*Right tubal pregnancy with intrauterine pregnancy*/
        "O00112" = "1"      /*Left tubal pregnancy with intrauterine pregnancy*/
        "O00119" = "1"      /*Unspecified tubal pregnancy with intrauterine pregnancy*/
        "O002" = "1"        /*Ovarian pregnancy*/
        "O0020" = "1"       /*Ovarian pregnancy without intrauterine pregnancy*/
        "O00201" = "1"      /*Right ovarian pregnancy without intrauterine pregnancy*/
        "O00202" = "1"      /*Left ovarian pregnancy without intrauterine pregnancy*/
        "O00209" = "1"      /*Unspecified ovarian pregnancy without intrauterine pregnancy*/
        "O0021" = "1"       /*Ovarian pregnancy with intrauterine pregnancy*/
        "O00211" = "1"      /*Right ovarian pregnancy with intrauterine pregnancy*/
        "O00212" = "1"      /*Left ovarian pregnancy with intrauterine pregnancy*/
        "O00219" = "1"      /*Unspecified ovarian pregnancy with intrauterine pregnancy*/
        "O008" = "1"        /*Other ectopic pregnancy*/
        "O0080" = "1"       /*Other ectopic pregnancy without intrauterine pregnancy*/
        "O0081" = "1"       /*Other ectopic pregnancy with intrauterine pregnancy*/
        "O009" = "1"        /*Ectopic pregnancy, unspecified*/
        "O0090" = "1"       /*Unspecified ectopic pregnancy without intrauterine pregnancy*/
        "O0091" = "1"       /*Unspecified ectopic pregnancy with intrauterine pregnancy*/
        "O010" = "1"        /*Classical hydatidiform mole*/
        "O011" = "1"        /*Incomplete and partial hydatidiform mole*/
        "O019" = "1"        /*Hydatidiform mole, unspecified*/
        "O020" = "1"        /*Blighted ovum and nonhydatidiform mole*/
        "O021" = "1"        /*Missed abortion*/
        "O0281" = "1"       /*Inapprop chg quantitav hCG in early pregnancy*/
        "O0289" = "1"       /*Other abnormal products of conception*/
        "O029" = "1"        /*Abnormal product of conception, unspecified*/
        "O030" = "1"        /*Genitl trct and pelvic infection fol incmpl spon abortion*/
        "O031" = "1"        /*Delayed or excessive hemor following incmpl spon abortion*/
        "O032" = "1"        /*Embolism following incomplete spontaneous abortion*/
        "O0330" = "1"       /*Unsp complication following incomplete spontaneous abortion*/
        "O0331" = "1"       /*Shock following incomplete spontaneous abortion*/
        "O0332" = "1"       /*Renal failure following incomplete spontaneous abortion*/
        "O0333" = "1"       /*Metabolic disorder following incomplete spontaneous abortion*/
        "O0334" = "1"       /*Damage to pelvic organs following incomplete spon abortion*/
        "O0335" = "1"       /*Oth venous comp following incomplete spontaneous abortion*/
        "O0336" = "1"       /*Cardiac arrest following incomplete spontaneous abortion*/
        "O0337" = "1"       /*Sepsis following incomplete spontaneous abortion*/
        "O0338" = "1"       /*Urinary tract infection following incomplete spon abortion*/
        "O0339" = "1"       /*Incomplete spontaneous abortion with other complications*/
        "O034" = "1"        /*Incomplete spontaneous abortion without complication*/
        "O035" = "1"        /*Genitl trct and pelvic infct fol complete or unsp spon abort*/
        "O036" = "1"        /*Delayed or excess hemor fol complete or unsp spon abortion*/
        "O037" = "1"        /*Embolism following complete or unsp spontaneous abortion*/
        "O0380" = "1"       /*Unsp comp following complete or unsp spontaneous abortion*/
        "O0381" = "1"       /*Shock following complete or unspecified spontaneous abortion*/
        "O0382" = "1"       /*Renal failure following complete or unsp spon abortion*/
        "O0383" = "1"       /*Metabolic disorder following complete or unsp spon abortion*/
        "O0384" = "1"       /*Damage to pelvic organs fol complete or unsp spon abortion*/
        "O0385" = "1"       /*Oth venous comp following complete or unsp spon abortion*/
        "O0386" = "1"       /*Cardiac arrest following complete or unsp spon abortion*/
        "O0387" = "1"       /*Sepsis following complete or unsp spontaneous abortion*/
        "O0388" = "1"       /*Urinary tract infection fol complete or unsp spon abortion*/
        "O0389" = "1"       /*Complete or unsp spontaneous abortion with oth complications*/
        "O039" = "1"        /*Complete or unsp spontaneous abortion without complication*/
        "O045" = "1"        /*Genitl trct and pelvic infct fol (induced) term of pregnancy*/
        "O046" = "1"        /*Delayed or excess hemor fol (induced) term of pregnancy*/
        "O047" = "1"        /*Embolism following (induced) termination of pregnancy*/
        "O0480" = "1"       /*(Induced) termination of pregnancy with unsp complications*/
        "O0481" = "1"       /*Shock following (induced) termination of pregnancy*/
        "O0482" = "1"       /*Renal failure following (induced) termination of pregnancy*/
        "O0483" = "1"       /*Metabolic disorder following (induced) term of pregnancy*/
        "O0484" = "1"       /*Damage to pelvic organs fol (induced) term of pregnancy*/
        "O0485" = "1"       /*Oth venous comp following (induced) termination of pregnancy*/
        "O0486" = "1"       /*Cardiac arrest following (induced) termination of pregnancy*/
        "O0487" = "1"       /*Sepsis following (induced) termination of pregnancy*/
        "O0488" = "1"       /*Urinary tract infection fol (induced) term of pregnancy*/
        "O0489" = "1"       /*(Induced) termination of pregnancy with other complications*/
        "O070" = "1"        /*Genitl trct and pelvic infct fol failed attempt term of preg*/
        "O071" = "1"        /*Delayed or excess hemor fol failed attempt term of pregnancy*/
        "O072" = "1"        /*Embolism following failed attempted termination of pregnancy*/
        "O0730" = "1"       /*Failed attempted termination of pregnancy w unsp comp*/
        "O0731" = "1"       /*Shock following failed attempted termination of pregnancy*/
        "O0732" = "1"       /*Renal failure following failed attempted term of pregnancy*/
        "O0733" = "1"       /*Metabolic disorder fol failed attempt term of pregnancy*/
        "O0734" = "1"       /*Damage to pelvic organs fol failed attempt term of pregnancy*/
        "O0735" = "1"       /*Oth venous comp following failed attempted term of pregnancy*/
        "O0736" = "1"       /*Cardiac arrest following failed attempted term of pregnancy*/
        "O0737" = "1"       /*Sepsis following failed attempted termination of pregnancy*/
        "O0738" = "1"       /*Urinary tract infection fol failed attempt term of pregnancy*/
        "O0739" = "1"       /*Failed attempted termination of pregnancy w oth comp*/
        "O074" = "1"        /*Failed attempted termination of pregnancy w/o complication*/
        "O080" = "1"        /*Genitl trct and pelvic infct fol ectopic and molar pregnancy*/
        "O081" = "1"        /*Delayed or excess hemor fol ectopic and molar pregnancy*/
        "O082" = "1"        /*Embolism following ectopic and molar pregnancy*/
        "O083" = "1"        /*Shock following ectopic and molar pregnancy*/
        "O084" = "1"        /*Renal failure following ectopic and molar pregnancy*/
        "O085" = "1"        /*Metabolic disorders following an ectopic and molar pregnancy*/
        "O086" = "1"        /*Damage to pelvic organs and tiss fol an ect and molar preg*/
        "O087" = "1"        /*Oth venous comp following an ectopic and molar pregnancy*/
        "O0881" = "1"       /*Cardiac arrest following an ectopic and molar pregnancy*/
        "O0882" = "1"       /*Sepsis following ectopic and molar pregnancy*/
        "O0883" = "1"       /*Urinary tract infection fol an ectopic and molar pregnancy*/
        "O0889" = "1"       /*Other complications following an ectopic and molar pregnancy*/
        "O089" = "1"        /*Unsp complication following an ectopic and molar pregnancy*/
        OTHER = "0";

    value $PR_Abortion
        '10A00ZZ' = '1'     /*Abortion of Products of Conception, Open Approach*/
        '10A03ZZ' = '1'     /*Abortion of Products of Conception, Percutaneous Approach*/
        '10A04ZZ' = '1'     /*Abortion of Products of Conception, Percutaneous Endoscopic Approach*/
        '10A07Z6' = '1'     /*Abortion of Products of Conception, Vacuum, Via Natural or Artificial Opening*/
        '10A07ZW' = '1'     /*Abortion of Products of Conception, Laminaria, Via Natural or Artificial Opening*/
        '10A07ZX' = '1'     /*Abortion of Products of Conception, Abortifacient, Via Natural or Artificial Opening*/
        '10A07ZZ' = '1'     /*Abortion of Products of Conception, Via Natural or Artificial Opening*/
        '10A08ZZ' = '1'     /*Abortion of Products of Conception, Via Natural or Artificial Opening Endoscopic*/
        OTHER = '0';



/* FORMAT FOR Cesarean delivery procedure codes */
Value $PRCSECP
"10D00Z0" = '1' /*Extraction of Products of Conception, High, Open Approach */
"10D00Z1" = '1' /*Extraction of Products of Conception, Low, Open Approach */
"10D00Z2" = '1' /*Extraction of Products of Conception, Extraperitoneal, Open Approach */
OTHER = '0'
;

/* FORMAT FOR Hysterotomy procedure codes */
Value $PRCSE2P
"10A00ZZ" = '1' /*Abortion of Products of Conception, Open Approach */
"10A03ZZ" = '1' /*Abortion of Products of Conception, Percutaneous Approach */
"10A04ZZ" = '1' /*Abortion of Products of Conception, Percutaneous Endoscopic Approach */
OTHER = '0'
;

/* FORMAT FOR Race/ethnicity categories */
Value RACECAT
1 = 'White' /*White */
2 = 'Black' /*Black */
3 = 'Hispanic' /*Hispanic */
4 = 'Asian and NH/PI' /*Asian and NH/PI */
5 = 'Amer Indian/AN' /*American Indian /AN */
6 = 'Other' /*Other */
;

/* FORMAT FOR Primary expected payer categories */
Value PAYCAT
1 = 'Medicare' /*Medicare */
2 = 'Medicaid' /*Medicaid */
3 = 'Private' /*Private */
4 = 'Self Pay' /*Self Pay */
5 = 'No Charge' /*No Charge */
6 = 'Other' /*Other */
;

/* FORMAT FOR Labeling county deciles in printed output - Based on 2021 Census Data */
Value POVCATLBL
0  = 'County not ranked'
1  = 'County decile 1:         percent in poverty <= 7.4 '
2  = 'County decile 2:   7.4 < percent in poverty <= 9.4 '
3  = 'County decile 3:   9.4 < percent in poverty <= 10.5'
4  = 'County decile 4:  10.5 < percent in poverty <= 11.6'
5  = 'County decile 5:  11.6 < percent in poverty <= 12.9'
6  = 'County decile 6:  12.9 < percent in poverty <= 14.4'
7  = 'County decile 7:  14.4 < percent in poverty <= 15.7'
8  = 'County decile 8:  15.7 < percent in poverty <= 16.9'
9  = 'County decile 9:  16.9 < percent in poverty <= 20.1'
10 = 'County decile 10: 20.1 < percent in poverty <= 43.5' 
;

/* FORMAT FOR County Poverty Deciles - Based on 2021 Census Data */
Value $POVCAT
"01001" = 4
"01003" = 4
"01005" = 10
"01007" = 10
"01009" = 5
"01011" = 10
"01013" = 10
"01015" = 10
"01017" = 10
"01019" = 9
"01021" = 8
"01023" = 10
"01025" = 10
"01027" = 9
"01029" = 8
"01031" = 8
"01033" = 9
"01035" = 10
"01037" = 9
"01039" = 10
"01041" = 9
"01043" = 6
"01045" = 8
"01047" = 10
"01049" = 10
"01051" = 5
"01053" = 10
"01055" = 9
"01057" = 10
"01059" = 10
"01061" = 10
"01063" = 10
"01065" = 10
"01067" = 8
"01069" = 10
"01071" = 10
"01073" = 9
"01075" = 9
"01077" = 9
"01079" = 7
"01081" = 9
"01083" = 3
"01085" = 10
"01087" = 10
"01089" = 4
"01091" = 10
"01093" = 9
"01095" = 8
"01097" = 9
"01099" = 10
"01101" = 10
"01103" = 6
"01105" = 10
"01107" = 10
"01109" = 10
"01111" = 10
"01113" = 10
"01115" = 6
"01117" = 2
"01119" = 10
"01121" = 10
"01123" = 9
"01125" = 8
"01127" = 10
"01129" = 10
"01131" = 10
"01133" = 10
"02013" = 9
"02016" = 4
"02020" = 3
"02050" = 10
"02060" = 4
"02068" = 2
"02070" = 10
"02090" = 2
"02100" = 4
"02105" = 9
"02110" = 2
"02122" = 5
"02130" = 4
"02150" = 2
"02158" = 10
"02164" = 10
"02170" = 4
"02180" = 10
"02185" = 5
"02188" = 10
"02195" = 2
"02198" = 8
"02220" = 2
"02230" = 1
"02240" = 6
"02261" = 4
"02275" = 4
"02282" = 5
"02290" = 10
"04001" = 10
"04003" = 9
"04005" = 9
"04007" = 9
"04009" = 10
"04011" = 3
"04012" = 10
"04013" = 4
"04015" = 9
"04017" = 10
"04019" = 8
"04021" = 4
"04023" = 10
"04025" = 6
"04027" = 9
"05001" = 9
"05003" = 10
"05005" = 6
"05007" = 2
"05009" = 6
"05011" = 10
"05013" = 8
"05015" = 9
"05017" = 10
"05019" = 10
"05021" = 9
"05023" = 9
"05025" = 7
"05027" = 10
"05029" = 9
"05031" = 9
"05033" = 8
"05035" = 10
"05037" = 9
"05039" = 10
"05041" = 10
"05043" = 9
"05045" = 6
"05047" = 9
"05049" = 9
"05051" = 7
"05053" = 4
"05055" = 6
"05057" = 10
"05059" = 9
"05061" = 9
"05063" = 10
"05065" = 9
"05067" = 10
"05069" = 10
"05071" = 9
"05073" = 10
"05075" = 10
"05077" = 10
"05079" = 10
"05081" = 8
"05083" = 8
"05085" = 4
"05087" = 8
"05089" = 9
"05091" = 10
"05093" = 10
"05095" = 10
"05097" = 10
"05099" = 10
"05101" = 10
"05103" = 10
"05105" = 8
"05107" = 10
"05109" = 10
"05111" = 10
"05113" = 10
"05115" = 9
"05117" = 8
"05119" = 9
"05121" = 9
"05123" = 10
"05125" = 2
"05127" = 9
"05129" = 10
"05131" = 10
"05133" = 9
"05135" = 9
"05137" = 10
"05139" = 9
"05141" = 9
"05143" = 5
"05145" = 9
"05147" = 10
"05149" = 8
"06001" = 3
"06003" = 8
"06005" = 4
"06007" = 9
"06009" = 6
"06011" = 5
"06013" = 2
"06015" = 10
"06017" = 2
"06019" = 10
"06021" = 8
"06023" = 10
"06025" = 9
"06027" = 6
"06029" = 9
"06031" = 9
"06033" = 9
"06035" = 10
"06037" = 7
"06039" = 10
"06041" = 2
"06043" = 7
"06045" = 9
"06047" = 10
"06049" = 10
"06051" = 3
"06053" = 5
"06055" = 2
"06057" = 5
"06059" = 3
"06061" = 1
"06063" = 6
"06065" = 5
"06067" = 6
"06069" = 2
"06071" = 6
"06073" = 4
"06075" = 5
"06077" = 5
"06079" = 6
"06081" = 1
"06083" = 8
"06085" = 1
"06087" = 4
"06089" = 7
"06091" = 5
"06093" = 9
"06095" = 3
"06097" = 3
"06099" = 7
"06101" = 8
"06103" = 8
"06105" = 10
"06107" = 10
"06109" = 6
"06111" = 2
"06113" = 8
"06115" = 8
"08001" = 3
"08003" = 9
"08005" = 2
"08007" = 5
"08009" = 10
"08011" = 10
"08013" = 4
"08014" = 1
"08015" = 4
"08017" = 6
"08019" = 2
"08021" = 9
"08023" = 10
"08025" = 10
"08027" = 4
"08029" = 7
"08031" = 5
"08033" = 7
"08035" = 1
"08037" = 1
"08039" = 1
"08041" = 3
"08043" = 8
"08045" = 3
"08047" = 1
"08049" = 1
"08051" = 5
"08053" = 2
"08055" = 10
"08057" = 8
"08059" = 1
"08061" = 6
"08063" = 5
"08065" = 4
"08067" = 4
"08069" = 4
"08071" = 10
"08073" = 8
"08075" = 9
"08077" = 4
"08079" = 3
"08081" = 4
"08083" = 8
"08085" = 6
"08087" = 5
"08089" = 10
"08091" = 1
"08093" = 1
"08095" = 5
"08097" = 1
"08099" = 10
"08101" = 9
"08103" = 4
"08105" = 7
"08107" = 1
"08109" = 10
"08111" = 7
"08113" = 2
"08115" = 7
"08117" = 1
"08119" = 2
"08121" = 5
"08123" = 3
"08125" = 6
"09001" = 3
"09003" = 4
"09005" = 2
"09007" = 1
"09009" = 5
"09011" = 2
"09013" = 4
"09015" = 5
"10001" = 5
"10003" = 5
"10005" = 5
"11001" = 9
"12001" = 10
"12003" = 9
"12005" = 7
"12007" = 10
"12009" = 4
"12011" = 6
"12013" = 10
"12015" = 4
"12017" = 8
"12019" = 2
"12021" = 4
"12023" = 9
"12027" = 10
"12029" = 10
"12031" = 8
"12033" = 9
"12035" = 4
"12037" = 10
"12039" = 10
"12041" = 8
"12043" = 10
"12045" = 8
"12047" = 10
"12049" = 10
"12051" = 10
"12053" = 5
"12055" = 8
"12057" = 7
"12059" = 10
"12061" = 5
"12063" = 10
"12065" = 9
"12067" = 10
"12069" = 3
"12071" = 5
"12073" = 9
"12075" = 10
"12077" = 10
"12079" = 10
"12081" = 3
"12083" = 6
"12085" = 5
"12086" = 8
"12087" = 4
"12089" = 3
"12091" = 3
"12093" = 10
"12095" = 8
"12097" = 6
"12099" = 5
"12101" = 5
"12103" = 5
"12105" = 8
"12107" = 10
"12109" = 1
"12111" = 5
"12113" = 2
"12115" = 2
"12117" = 3
"12119" = 3
"12121" = 10
"12123" = 10
"12125" = 10
"12127" = 7
"12129" = 4
"12131" = 5
"12133" = 10
"13001" = 9
"13003" = 10
"13005" = 10
"13007" = 10
"13009" = 10
"13011" = 6
"13013" = 3
"13015" = 5
"13017" = 10
"13019" = 9
"13021" = 10
"13023" = 10
"13025" = 9
"13027" = 10
"13029" = 2
"13031" = 10
"13033" = 10
"13035" = 7
"13037" = 10
"13039" = 5
"13043" = 10
"13045" = 9
"13047" = 5
"13049" = 10
"13051" = 8
"13053" = 9
"13055" = 10
"13057" = 1
"13059" = 10
"13061" = 10
"13063" = 10
"13065" = 10
"13067" = 3
"13069" = 10
"13071" = 10
"13073" = 1
"13075" = 10
"13077" = 2
"13079" = 9
"13081" = 10
"13083" = 4
"13085" = 2
"13087" = 10
"13089" = 7
"13091" = 10
"13093" = 10
"13095" = 10
"13097" = 6
"13099" = 10
"13101" = 10
"13103" = 3
"13105" = 10
"13107" = 10
"13109" = 10
"13111" = 6
"13113" = 1
"13115" = 9
"13117" = 1
"13119" = 9
"13121" = 6
"13123" = 7
"13125" = 8
"13127" = 9
"13129" = 6
"13131" = 10
"13133" = 7
"13135" = 4
"13137" = 6
"13139" = 5
"13141" = 10
"13143" = 8
"13145" = 2
"13147" = 8
"13149" = 9
"13151" = 3
"13153" = 5
"13155" = 10
"13157" = 5
"13159" = 8
"13161" = 10
"13163" = 10
"13165" = 10
"13167" = 10
"13169" = 6
"13171" = 7
"13173" = 10
"13175" = 10
"13177" = 3
"13179" = 9
"13181" = 9
"13183" = 8
"13185" = 10
"13187" = 6
"13189" = 10
"13191" = 10
"13193" = 10
"13195" = 8
"13197" = 10
"13199" = 10
"13201" = 10
"13205" = 10
"13207" = 5
"13209" = 10
"13211" = 4
"13213" = 8
"13215" = 10
"13217" = 6
"13219" = 1
"13221" = 6
"13223" = 2
"13225" = 10
"13227" = 4
"13229" = 8
"13231" = 3
"13233" = 9
"13235" = 10
"13237" = 9
"13239" = 10
"13241" = 6
"13243" = 10
"13245" = 10
"13247" = 6
"13249" = 9
"13251" = 10
"13253" = 10
"13255" = 10
"13257" = 9
"13259" = 10
"13261" = 10
"13263" = 10
"13265" = 10
"13267" = 10
"13269" = 10
"13271" = 10
"13273" = 10
"13275" = 10
"13277" = 10
"13279" = 10
"13281" = 6
"13283" = 10
"13285" = 8
"13287" = 10
"13289" = 10
"13291" = 5
"13293" = 10
"13295" = 7
"13297" = 4
"13299" = 10
"13301" = 10
"13303" = 10
"13305" = 10
"13307" = 10
"13309" = 10
"13311" = 6
"13313" = 6
"13315" = 10
"13317" = 10
"13319" = 10
"13321" = 10
"15001" = 8
"15003" = 3
"15005" = 1
"15007" = 4
"15009" = 5
"16001" = 2
"16003" = 6
"16005" = 6
"16007" = 3
"16009" = 6
"16011" = 4
"16013" = 1
"16015" = 5
"16017" = 5
"16019" = 3
"16021" = 5
"16023" = 8
"16025" = 3
"16027" = 4
"16029" = 3
"16031" = 4
"16033" = 7
"16035" = 8
"16037" = 6
"16039" = 4
"16041" = 2
"16043" = 5
"16045" = 5
"16047" = 4
"16049" = 6
"16051" = 2
"16053" = 6
"16055" = 3
"16057" = 6
"16059" = 5
"16061" = 6
"16063" = 4
"16065" = 9
"16067" = 7
"16069" = 8
"16071" = 4
"16073" = 7
"16075" = 5
"16077" = 6
"16079" = 9
"16081" = 1
"16083" = 6
"16085" = 2
"16087" = 6
"17001" = 5
"17003" = 10
"17005" = 6
"17007" = 4
"17009" = 9
"17011" = 5
"17013" = 4
"17015" = 6
"17017" = 5
"17019" = 8
"17021" = 5
"17023" = 4
"17025" = 7
"17027" = 3
"17029" = 9
"17031" = 7
"17033" = 6
"17035" = 4
"17037" = 7
"17039" = 4
"17041" = 3
"17043" = 1
"17045" = 6
"17047" = 5
"17049" = 3
"17051" = 8
"17053" = 4
"17055" = 9
"17057" = 8
"17059" = 9
"17061" = 7
"17063" = 1
"17065" = 6
"17067" = 5
"17069" = 10
"17071" = 5
"17073" = 3
"17075" = 4
"17077" = 10
"17079" = 3
"17081" = 8
"17083" = 3
"17085" = 2
"17087" = 6
"17089" = 2
"17091" = 6
"17093" = 1
"17095" = 8
"17097" = 2
"17099" = 6
"17101" = 10
"17103" = 6
"17105" = 5
"17107" = 6
"17109" = 9
"17111" = 1
"17113" = 6
"17115" = 9
"17117" = 8
"17119" = 5
"17121" = 8
"17123" = 3
"17125" = 5
"17127" = 9
"17129" = 2
"17131" = 4
"17133" = 1
"17135" = 6
"17137" = 7
"17139" = 3
"17141" = 2
"17143" = 9
"17145" = 9
"17147" = 1
"17149" = 6
"17151" = 9
"17153" = 10
"17155" = 2
"17157" = 8
"17159" = 7
"17161" = 9
"17163" = 6
"17165" = 9
"17167" = 7
"17169" = 5
"17171" = 5
"17173" = 4
"17175" = 5
"17177" = 5
"17179" = 3
"17181" = 9
"17183" = 10
"17185" = 7
"17187" = 6
"17189" = 2
"17191" = 7
"17193" = 8
"17195" = 6
"17197" = 2
"17199" = 8
"17201" = 7
"17203" = 1
"18001" = 6
"18003" = 6
"18005" = 2
"18007" = 4
"18009" = 6
"18011" = 1
"18013" = 4
"18015" = 2
"18017" = 5
"18019" = 4
"18021" = 4
"18023" = 4
"18025" = 8
"18027" = 6
"18029" = 2
"18031" = 3
"18033" = 2
"18035" = 9
"18037" = 2
"18039" = 4
"18041" = 6
"18043" = 3
"18045" = 4
"18047" = 2
"18049" = 4
"18051" = 5
"18053" = 10
"18055" = 7
"18057" = 1
"18059" = 1
"18061" = 2
"18063" = 1
"18065" = 8
"18067" = 5
"18069" = 4
"18071" = 7
"18073" = 2
"18075" = 6
"18077" = 5
"18079" = 6
"18081" = 2
"18083" = 8
"18085" = 3
"18087" = 2
"18089" = 7
"18091" = 5
"18093" = 6
"18095" = 8
"18097" = 8
"18099" = 2
"18101" = 5
"18103" = 8
"18105" = 10
"18107" = 5
"18109" = 4
"18111" = 5
"18113" = 3
"18115" = 3
"18117" = 7
"18119" = 4
"18121" = 9
"18123" = 6
"18125" = 4
"18127" = 3
"18129" = 3
"18131" = 5
"18133" = 5
"18135" = 7
"18137" = 2
"18139" = 4
"18141" = 7
"18143" = 7
"18145" = 3
"18147" = 2
"18149" = 7
"18151" = 3
"18153" = 9
"18155" = 7
"18157" = 9
"18159" = 2
"18161" = 4
"18163" = 7
"18165" = 5
"18167" = 10
"18169" = 4
"18171" = 2
"18173" = 1
"18175" = 4
"18177" = 8
"18179" = 2
"18181" = 3
"18183" = 1
"19001" = 4
"19003" = 4
"19005" = 3
"19007" = 9
"19009" = 4
"19011" = 2
"19013" = 6
"19015" = 2
"19017" = 1
"19019" = 3
"19021" = 4
"19023" = 2
"19025" = 5
"19027" = 3
"19029" = 7
"19031" = 1
"19033" = 5
"19035" = 4
"19037" = 2
"19039" = 3
"19041" = 3
"19043" = 3
"19045" = 5
"19047" = 5
"19049" = 1
"19051" = 4
"19053" = 9
"19055" = 3
"19057" = 6
"19059" = 2
"19061" = 2
"19063" = 5
"19065" = 5
"19067" = 4
"19069" = 4
"19071" = 4
"19073" = 4
"19075" = 1
"19077" = 3
"19079" = 2
"19081" = 2
"19083" = 3
"19085" = 4
"19087" = 5
"19089" = 3
"19091" = 3
"19093" = 4
"19095" = 2
"19097" = 5
"19099" = 3
"19101" = 6
"19103" = 8
"19105" = 4
"19107" = 4
"19109" = 4
"19111" = 7
"19113" = 3
"19115" = 4
"19117" = 6
"19119" = 1
"19121" = 1
"19123" = 6
"19125" = 2
"19127" = 5
"19129" = 2
"19131" = 2
"19133" = 5
"19135" = 4
"19137" = 5
"19139" = 4
"19141" = 4
"19143" = 2
"19145" = 9
"19147" = 5
"19149" = 1
"19151" = 4
"19153" = 4
"19155" = 5
"19157" = 6
"19159" = 6
"19161" = 3
"19163" = 6
"19165" = 2
"19167" = 1
"19169" = 9
"19171" = 6
"19173" = 6
"19175" = 6
"19177" = 6
"19179" = 8
"19181" = 1
"19183" = 2
"19185" = 6
"19187" = 8
"19189" = 4
"19191" = 2
"19193" = 8
"19195" = 3
"19197" = 4
"20001" = 9
"20003" = 5
"20005" = 8
"20007" = 4
"20009" = 7
"20011" = 8
"20013" = 7
"20015" = 3
"20017" = 4
"20019" = 8
"20021" = 8
"20023" = 7
"20025" = 5
"20027" = 3
"20029" = 6
"20031" = 3
"20033" = 3
"20035" = 7
"20037" = 10
"20039" = 5
"20041" = 3
"20043" = 6
"20045" = 8
"20047" = 5
"20049" = 9
"20051" = 6
"20053" = 4
"20055" = 6
"20057" = 5
"20059" = 4
"20061" = 6
"20063" = 3
"20065" = 5
"20067" = 4
"20069" = 2
"20071" = 3
"20073" = 8
"20075" = 5
"20077" = 9
"20079" = 3
"20081" = 3
"20083" = 3
"20085" = 3
"20087" = 2
"20089" = 6
"20091" = 1
"20093" = 4
"20095" = 5
"20097" = 5
"20099" = 9
"20101" = 3
"20103" = 2
"20105" = 4
"20107" = 5
"20109" = 2
"20111" = 7
"20113" = 2
"20115" = 4
"20117" = 4
"20119" = 3
"20121" = 1
"20123" = 4
"20125" = 8
"20127" = 4
"20129" = 4
"20131" = 2
"20133" = 8
"20135" = 3
"20137" = 6
"20139" = 4
"20141" = 5
"20143" = 4
"20145" = 8
"20147" = 5
"20149" = 2
"20151" = 5
"20153" = 5
"20155" = 6
"20157" = 4
"20159" = 6
"20161" = 9
"20163" = 3
"20165" = 6
"20167" = 7
"20169" = 6
"20171" = 1
"20173" = 6
"20175" = 6
"20177" = 8
"20179" = 4
"20181" = 6
"20183" = 5
"20185" = 5
"20187" = 4
"20189" = 3
"20191" = 5
"20193" = 2
"20195" = 4
"20197" = 2
"20199" = 5
"20201" = 3
"20203" = 4
"20205" = 9
"20207" = 7
"20209" = 9
"21001" = 10
"21003" = 9
"21005" = 2
"21007" = 7
"21009" = 10
"21011" = 10
"21013" = 10
"21015" = 1
"21017" = 8
"21019" = 10
"21021" = 8
"21023" = 8
"21025" = 10
"21027" = 9
"21029" = 4
"21031" = 9
"21033" = 9
"21035" = 9
"21037" = 4
"21039" = 8
"21041" = 9
"21043" = 10
"21045" = 10
"21047" = 9
"21049" = 5
"21051" = 10
"21053" = 10
"21055" = 10
"21057" = 10
"21059" = 6
"21061" = 9
"21063" = 10
"21065" = 10
"21067" = 8
"21069" = 9
"21071" = 10
"21073" = 6
"21075" = 10
"21077" = 8
"21079" = 7
"21081" = 6
"21083" = 9
"21085" = 9
"21087" = 10
"21089" = 8
"21091" = 6
"21093" = 5
"21095" = 10
"21097" = 7
"21099" = 10
"21101" = 5
"21103" = 7
"21105" = 10
"21107" = 10
"21109" = 10
"21111" = 7
"21113" = 7
"21115" = 10
"21117" = 6
"21119" = 10
"21121" = 10
"21123" = 8
"21125" = 10
"21127" = 10
"21129" = 10
"21131" = 10
"21133" = 10
"21135" = 10
"21137" = 10
"21139" = 7
"21141" = 9
"21143" = 8
"21145" = 9
"21147" = 10
"21149" = 6
"21151" = 9
"21153" = 10
"21155" = 8
"21157" = 6
"21159" = 10
"21161" = 9
"21163" = 8
"21165" = 10
"21167" = 6
"21169" = 10
"21171" = 10
"21173" = 9
"21175" = 10
"21177" = 10
"21179" = 4
"21181" = 9
"21183" = 9
"21185" = 1
"21187" = 8
"21189" = 10
"21191" = 8
"21193" = 10
"21195" = 10
"21197" = 10
"21199" = 10
"21201" = 9
"21203" = 10
"21205" = 10
"21207" = 10
"21209" = 3
"21211" = 3
"21213" = 6
"21215" = 1
"21217" = 9
"21219" = 10
"21221" = 9
"21223" = 6
"21225" = 9
"21227" = 8
"21229" = 6
"21231" = 10
"21233" = 8
"21235" = 10
"21237" = 10
"21239" = 2
"22001" = 10
"22003" = 10
"22005" = 5
"22007" = 10
"22009" = 10
"22011" = 8
"22013" = 10
"22015" = 8
"22017" = 10
"22019" = 9
"22021" = 10
"22023" = 7
"22025" = 10
"22027" = 10
"22029" = 10
"22031" = 10
"22033" = 10
"22035" = 10
"22037" = 10
"22039" = 10
"22041" = 10
"22043" = 10
"22045" = 10
"22047" = 10
"22049" = 10
"22051" = 9
"22053" = 9
"22055" = 9
"22057" = 8
"22059" = 10
"22061" = 10
"22063" = 5
"22065" = 10
"22067" = 10
"22069" = 10
"22071" = 10
"22073" = 10
"22075" = 7
"22077" = 10
"22079" = 10
"22081" = 10
"22083" = 10
"22085" = 10
"22087" = 10
"22089" = 5
"22091" = 10
"22093" = 9
"22095" = 9
"22097" = 10
"22099" = 9
"22101" = 10
"22103" = 6
"22105" = 9
"22107" = 10
"22109" = 9
"22111" = 10
"22113" = 10
"22115" = 9
"22117" = 10
"22119" = 10
"22121" = 8
"22123" = 10
"22125" = 10
"22127" = 10
"23001" = 7
"23003" = 8
"23005" = 2
"23007" = 5
"23009" = 4
"23011" = 4
"23013" = 4
"23015" = 3
"23017" = 8
"23019" = 8
"23021" = 7
"23023" = 2
"23025" = 8
"23027" = 6
"23029" = 9
"23031" = 2
"24001" = 9
"24003" = 1
"24005" = 3
"24009" = 1
"24011" = 6
"24013" = 1
"24015" = 4
"24017" = 1
"24019" = 8
"24021" = 1
"24023" = 4
"24025" = 2
"24027" = 1
"24029" = 5
"24031" = 2
"24033" = 5
"24035" = 2
"24037" = 2
"24039" = 10
"24041" = 3
"24043" = 7
"24045" = 7
"24047" = 4
"24510" = 10
"25001" = 2
"25003" = 4
"25005" = 5
"25007" = 2
"25009" = 3
"25011" = 4
"25013" = 9
"25015" = 5
"25017" = 2
"25019" = 1
"25021" = 1
"25023" = 2
"25025" = 9
"25027" = 3
"26001" = 6
"26003" = 6
"26005" = 3
"26007" = 8
"26009" = 4
"26011" = 8
"26013" = 8
"26015" = 2
"26017" = 6
"26019" = 3
"26021" = 9
"26023" = 6
"26025" = 6
"26027" = 5
"26029" = 3
"26031" = 6
"26033" = 9
"26035" = 10
"26037" = 2
"26039" = 8
"26041" = 5
"26043" = 5
"26045" = 2
"26047" = 2
"26049" = 9
"26051" = 8
"26053" = 9
"26055" = 2
"26057" = 8
"26059" = 7
"26061" = 7
"26063" = 5
"26065" = 8
"26067" = 5
"26069" = 7
"26071" = 8
"26073" = 9
"26075" = 5
"26077" = 7
"26079" = 4
"26081" = 3
"26083" = 4
"26085" = 10
"26087" = 3
"26089" = 1
"26091" = 4
"26093" = 1
"26095" = 10
"26097" = 5
"26099" = 5
"26101" = 6
"26103" = 6
"26105" = 7
"26107" = 9
"26109" = 4
"26111" = 4
"26113" = 5
"26115" = 3
"26117" = 6
"26119" = 9
"26121" = 7
"26123" = 7
"26125" = 2
"26127" = 7
"26129" = 9
"26131" = 5
"26133" = 6
"26135" = 9
"26137" = 4
"26139" = 2
"26141" = 6
"26143" = 9
"26145" = 10
"26147" = 4
"26149" = 5
"26151" = 7
"26153" = 7
"26155" = 4
"26157" = 6
"26159" = 6
"26161" = 5
"26163" = 10
"26165" = 8
"27001" = 4
"27003" = 1
"27005" = 4
"27007" = 8
"27009" = 2
"27011" = 6
"27013" = 6
"27015" = 3
"27017" = 4
"27019" = 1
"27021" = 5
"27023" = 4
"27025" = 1
"27027" = 6
"27029" = 7
"27031" = 3
"27033" = 5
"27035" = 4
"27037" = 1
"27039" = 1
"27041" = 3
"27043" = 5
"27045" = 5
"27047" = 4
"27049" = 2
"27051" = 3
"27053" = 3
"27055" = 1
"27057" = 4
"27059" = 2
"27061" = 5
"27063" = 4
"27065" = 6
"27067" = 5
"27069" = 3
"27071" = 6
"27073" = 3
"27075" = 2
"27077" = 4
"27079" = 1
"27081" = 2
"27083" = 4
"27085" = 2
"27087" = 10
"27089" = 3
"27091" = 4
"27093" = 2
"27095" = 4
"27097" = 4
"27099" = 5
"27101" = 2
"27103" = 3
"27105" = 5
"27107" = 5
"27109" = 2
"27111" = 3
"27113" = 3
"27115" = 4
"27117" = 4
"27119" = 5
"27121" = 2
"27123" = 6
"27125" = 3
"27127" = 3
"27129" = 4
"27131" = 3
"27133" = 3
"27135" = 3
"27137" = 7
"27139" = 1
"27141" = 1
"27143" = 2
"27145" = 6
"27147" = 3
"27149" = 5
"27151" = 4
"27153" = 6
"27155" = 6
"27157" = 1
"27159" = 6
"27161" = 2
"27163" = 1
"27165" = 5
"27167" = 3
"27169" = 5
"27171" = 1
"27173" = 4
"28001" = 10
"28003" = 9
"28005" = 10
"28007" = 10
"28009" = 10
"28011" = 10
"28013" = 10
"28015" = 8
"28017" = 10
"28019" = 10
"28021" = 10
"28023" = 9
"28025" = 10
"28027" = 10
"28029" = 10
"28031" = 10
"28033" = 4
"28035" = 10
"28037" = 10
"28039" = 9
"28041" = 10
"28043" = 10
"28045" = 9
"28047" = 9
"28049" = 10
"28051" = 10
"28053" = 10
"28055" = 10
"28057" = 6
"28059" = 8
"28061" = 9
"28063" = 10
"28065" = 10
"28067" = 10
"28069" = 10
"28071" = 9
"28073" = 5
"28075" = 10
"28077" = 10
"28079" = 10
"28081" = 8
"28083" = 10
"28085" = 9
"28087" = 9
"28089" = 5
"28091" = 10
"28093" = 10
"28095" = 9
"28097" = 10
"28099" = 10
"28101" = 10
"28103" = 10
"28105" = 10
"28107" = 10
"28109" = 9
"28111" = 10
"28113" = 10
"28115" = 9
"28117" = 9
"28119" = 10
"28121" = 4
"28123" = 10
"28125" = 10
"28127" = 10
"28129" = 9
"28131" = 9
"28133" = 10
"28135" = 10
"28137" = 8
"28139" = 10
"28141" = 8
"28143" = 10
"28145" = 7
"28147" = 10
"28149" = 10
"28151" = 10
"28153" = 10
"28155" = 9
"28157" = 10
"28159" = 10
"28161" = 10
"28163" = 10
"29001" = 10
"29003" = 2
"29005" = 6
"29007" = 9
"29009" = 10
"29011" = 8
"29013" = 6
"29015" = 8
"29017" = 8
"29019" = 9
"29021" = 10
"29023" = 10
"29025" = 6
"29027" = 4
"29029" = 6
"29031" = 5
"29033" = 5
"29035" = 10
"29037" = 1
"29039" = 9
"29041" = 5
"29043" = 2
"29045" = 6
"29047" = 2
"29049" = 4
"29051" = 5
"29053" = 6
"29055" = 8
"29057" = 8
"29059" = 9
"29061" = 6
"29063" = 6
"29065" = 9
"29067" = 10
"29069" = 10
"29071" = 3
"29073" = 4
"29075" = 7
"29077" = 6
"29079" = 9
"29081" = 8
"29083" = 7
"29085" = 9
"29087" = 7
"29089" = 5
"29091" = 9
"29093" = 10
"29095" = 6
"29097" = 9
"29099" = 2
"29101" = 5
"29103" = 9
"29105" = 8
"29107" = 4
"29109" = 8
"29111" = 8
"29113" = 3
"29115" = 8
"29117" = 7
"29119" = 9
"29121" = 6
"29123" = 7
"29125" = 4
"29127" = 7
"29129" = 6
"29131" = 8
"29133" = 10
"29135" = 5
"29137" = 8
"29139" = 6
"29141" = 9
"29143" = 10
"29145" = 8
"29147" = 8
"29149" = 10
"29151" = 2
"29153" = 10
"29155" = 10
"29157" = 4
"29159" = 9
"29161" = 9
"29163" = 9
"29165" = 1
"29167" = 8
"29169" = 6
"29171" = 7
"29173" = 3
"29175" = 8
"29177" = 4
"29179" = 9
"29181" = 10
"29183" = 1
"29185" = 9
"29186" = 4
"29187" = 9
"29189" = 4
"29195" = 6
"29197" = 6
"29199" = 7
"29201" = 8
"29203" = 10
"29205" = 7
"29207" = 9
"29209" = 8
"29211" = 9
"29213" = 8
"29215" = 10
"29217" = 10
"29219" = 2
"29221" = 10
"29223" = 10
"29225" = 8
"29227" = 7
"29229" = 10
"29510" = 10
"30001" = 6
"30003" = 10
"30005" = 10
"30007" = 2
"30009" = 3
"30011" = 6
"30013" = 6
"30015" = 7
"30017" = 6
"30019" = 4
"30021" = 4
"30023" = 8
"30025" = 2
"30027" = 5
"30029" = 3
"30031" = 2
"30033" = 8
"30035" = 10
"30037" = 9
"30039" = 5
"30041" = 9
"30043" = 1
"30045" = 8
"30047" = 9
"30049" = 2
"30051" = 9
"30053" = 9
"30055" = 7
"30057" = 3
"30059" = 8
"30061" = 7
"30063" = 6
"30065" = 8
"30067" = 3
"30069" = 6
"30071" = 7
"30073" = 9
"30075" = 4
"30077" = 9
"30079" = 6
"30081" = 3
"30083" = 3
"30085" = 10
"30087" = 9
"30089" = 8
"30091" = 5
"30093" = 6
"30095" = 2
"30097" = 3
"30099" = 6
"30101" = 8
"30103" = 5
"30105" = 5
"30107" = 9
"30109" = 4
"30111" = 4
"31001" = 5
"31003" = 3
"31005" = 6
"31007" = 4
"31009" = 6
"31011" = 3
"31013" = 4
"31015" = 7
"31017" = 4
"31019" = 4
"31021" = 3
"31023" = 2
"31025" = 1
"31027" = 2
"31029" = 2
"31031" = 4
"31033" = 5
"31035" = 3
"31037" = 2
"31039" = 2
"31041" = 4
"31043" = 4
"31045" = 8
"31047" = 4
"31049" = 4
"31051" = 2
"31053" = 4
"31055" = 5
"31057" = 7
"31059" = 2
"31061" = 6
"31063" = 5
"31065" = 5
"31067" = 5
"31069" = 8
"31071" = 4
"31073" = 2
"31075" = 3
"31077" = 6
"31079" = 5
"31081" = 1
"31083" = 3
"31085" = 7
"31087" = 6
"31089" = 4
"31091" = 1
"31093" = 2
"31095" = 3
"31097" = 6
"31099" = 2
"31101" = 5
"31103" = 10
"31105" = 5
"31107" = 5
"31109" = 5
"31111" = 4
"31113" = 3
"31115" = 8
"31117" = 5
"31119" = 3
"31121" = 2
"31123" = 6
"31125" = 4
"31127" = 5
"31129" = 3
"31131" = 3
"31133" = 5
"31135" = 3
"31137" = 2
"31139" = 4
"31141" = 2
"31143" = 1
"31145" = 4
"31147" = 5
"31149" = 7
"31151" = 4
"31153" = 1
"31155" = 1
"31157" = 6
"31159" = 2
"31161" = 6
"31163" = 4
"31165" = 8
"31167" = 1
"31169" = 2
"31171" = 5
"31173" = 10
"31175" = 5
"31177" = 1
"31179" = 6
"31181" = 5
"31183" = 4
"31185" = 2
"32001" = 4
"32003" = 8
"32005" = 2
"32007" = 3
"32009" = 7
"32011" = 3
"32013" = 4
"32015" = 4
"32017" = 7
"32019" = 3
"32021" = 9
"32023" = 8
"32027" = 9
"32029" = 1
"32031" = 4
"32033" = 6
"32510" = 5
"33001" = 2
"33003" = 2
"33005" = 3
"33007" = 6
"33009" = 2
"33011" = 1
"33013" = 2
"33015" = 1
"33017" = 2
"33019" = 3
"34001" = 8
"34003" = 2
"34005" = 2
"34007" = 5
"34009" = 2
"34011" = 7
"34013" = 8
"34015" = 2
"34017" = 8
"34019" = 1
"34021" = 4
"34023" = 2
"34025" = 1
"34027" = 1
"34029" = 5
"34031" = 7
"34033" = 5
"34035" = 1
"34037" = 1
"34039" = 3
"34041" = 3
"35001" = 8
"35003" = 10
"35005" = 10
"35006" = 10
"35007" = 10
"35009" = 10
"35011" = 10
"35013" = 10
"35015" = 7
"35017" = 10
"35019" = 10
"35021" = 9
"35023" = 10
"35025" = 10
"35027" = 9
"35028" = 1
"35029" = 10
"35031" = 10
"35033" = 10
"35035" = 10
"35037" = 10
"35039" = 10
"35041" = 10
"35043" = 3
"35045" = 10
"35047" = 10
"35049" = 5
"35051" = 10
"35053" = 10
"35055" = 10
"35057" = 10
"35059" = 10
"35061" = 10
"36001" = 5
"36003" = 8
"36005" = 10
"36007" = 7
"36009" = 9
"36011" = 8
"36013" = 9
"36015" = 8
"36017" = 6
"36019" = 8
"36021" = 4
"36023" = 4
"36025" = 8
"36027" = 3
"36029" = 6
"36031" = 4
"36033" = 9
"36035" = 6
"36037" = 3
"36039" = 5
"36041" = 3
"36043" = 6
"36045" = 5
"36047" = 10
"36049" = 6
"36051" = 5
"36053" = 4
"36055" = 6
"36057" = 8
"36059" = 1
"36061" = 9
"36063" = 6
"36065" = 7
"36067" = 7
"36069" = 2
"36071" = 5
"36073" = 9
"36075" = 8
"36077" = 7
"36079" = 1
"36081" = 6
"36083" = 5
"36085" = 5
"36087" = 8
"36089" = 8
"36091" = 2
"36093" = 6
"36095" = 6
"36097" = 6
"36099" = 6
"36101" = 6
"36103" = 1
"36105" = 9
"36107" = 5
"36109" = 9
"36111" = 4
"36113" = 4
"36115" = 5
"36117" = 3
"36119" = 3
"36121" = 3
"36123" = 4
"37001" = 6
"37003" = 6
"37005" = 9
"37007" = 10
"37009" = 7
"37011" = 9
"37013" = 10
"37015" = 10
"37017" = 10
"37019" = 3
"37021" = 5
"37023" = 7
"37025" = 3
"37027" = 8
"37029" = 2
"37031" = 5
"37033" = 10
"37035" = 6
"37037" = 5
"37039" = 7
"37041" = 9
"37043" = 7
"37045" = 9
"37047" = 10
"37049" = 6
"37051" = 8
"37053" = 2
"37055" = 2
"37057" = 6
"37059" = 3
"37061" = 10
"37063" = 6
"37065" = 10
"37067" = 7
"37069" = 6
"37071" = 8
"37073" = 6
"37075" = 9
"37077" = 7
"37079" = 10
"37081" = 6
"37083" = 10
"37085" = 6
"37087" = 6
"37089" = 5
"37091" = 10
"37093" = 8
"37095" = 10
"37097" = 3
"37099" = 10
"37101" = 5
"37103" = 9
"37105" = 8
"37107" = 10
"37109" = 2
"37111" = 7
"37113" = 7
"37115" = 8
"37117" = 10
"37119" = 4
"37121" = 8
"37123" = 9
"37125" = 3
"37127" = 8
"37129" = 5
"37131" = 10
"37133" = 7
"37135" = 5
"37137" = 8
"37139" = 8
"37141" = 4
"37143" = 8
"37145" = 9
"37147" = 10
"37149" = 5
"37151" = 6
"37153" = 10
"37155" = 10
"37157" = 9
"37159" = 9
"37161" = 9
"37163" = 10
"37165" = 10
"37167" = 7
"37169" = 6
"37171" = 9
"37173" = 9
"37175" = 6
"37177" = 10
"37179" = 2
"37181" = 10
"37183" = 3
"37185" = 10
"37187" = 10
"37189" = 10
"37191" = 10
"37193" = 9
"37195" = 10
"37197" = 6
"37199" = 9
"38001" = 5
"38003" = 4
"38005" = 10
"38007" = 4
"38009" = 4
"38011" = 2
"38013" = 2
"38015" = 2
"38017" = 4
"38019" = 2
"38021" = 4
"38023" = 4
"38025" = 4
"38027" = 5
"38029" = 6
"38031" = 2
"38033" = 6
"38035" = 6
"38037" = 9
"38039" = 4
"38041" = 7
"38043" = 7
"38045" = 4
"38047" = 7
"38049" = 5
"38051" = 7
"38053" = 3
"38055" = 4
"38057" = 2
"38059" = 3
"38061" = 4
"38063" = 4
"38065" = 4
"38067" = 3
"38069" = 5
"38071" = 5
"38073" = 2
"38075" = 2
"38077" = 4
"38079" = 10
"38081" = 2
"38083" = 9
"38085" = 10
"38087" = 6
"38089" = 4
"38091" = 2
"38093" = 5
"38095" = 5
"38097" = 3
"38099" = 5
"38101" = 3
"38103" = 5
"38105" = 2
"39001" = 10
"39003" = 8
"39005" = 4
"39007" = 8
"39009" = 10
"39011" = 2
"39013" = 8
"39015" = 9
"39017" = 5
"39019" = 6
"39021" = 4
"39023" = 9
"39025" = 3
"39027" = 5
"39029" = 9
"39031" = 7
"39033" = 6
"39035" = 9
"39037" = 4
"39039" = 4
"39041" = 1
"39043" = 6
"39045" = 2
"39047" = 9
"39049" = 7
"39051" = 2
"39053" = 9
"39055" = 1
"39057" = 4
"39059" = 8
"39061" = 8
"39063" = 3
"39065" = 9
"39067" = 7
"39069" = 2
"39071" = 7
"39073" = 9
"39075" = 4
"39077" = 4
"39079" = 9
"39081" = 9
"39083" = 6
"39085" = 1
"39087" = 9
"39089" = 4
"39091" = 4
"39093" = 6
"39095" = 9
"39097" = 6
"39099" = 10
"39101" = 8
"39103" = 1
"39105" = 10
"39107" = 1
"39109" = 2
"39111" = 7
"39113" = 8
"39115" = 9
"39117" = 4
"39119" = 8
"39121" = 9
"39123" = 2
"39125" = 4
"39127" = 7
"39129" = 4
"39131" = 10
"39133" = 5
"39135" = 4
"39137" = 1
"39139" = 6
"39141" = 10
"39143" = 6
"39145" = 10
"39147" = 5
"39149" = 4
"39151" = 6
"39153" = 6
"39155" = 8
"39157" = 5
"39159" = 1
"39161" = 2
"39163" = 10
"39165" = 1
"39167" = 6
"39169" = 3
"39171" = 2
"39173" = 4
"39175" = 2
"40001" = 10
"40003" = 9
"40005" = 9
"40007" = 5
"40009" = 9
"40011" = 9
"40013" = 9
"40015" = 10
"40017" = 2
"40019" = 7
"40021" = 10
"40023" = 10
"40025" = 8
"40027" = 5
"40029" = 10
"40031" = 10
"40033" = 9
"40035" = 9
"40037" = 7
"40039" = 9
"40041" = 9
"40043" = 9
"40045" = 6
"40047" = 6
"40049" = 8
"40051" = 6
"40053" = 7
"40055" = 10
"40057" = 10
"40059" = 5
"40061" = 10
"40063" = 10
"40065" = 8
"40067" = 10
"40069" = 10
"40071" = 8
"40073" = 4
"40075" = 10
"40077" = 10
"40079" = 10
"40081" = 8
"40083" = 6
"40085" = 8
"40087" = 3
"40089" = 10
"40091" = 9
"40093" = 4
"40095" = 8
"40097" = 8
"40099" = 6
"40101" = 10
"40103" = 5
"40105" = 8
"40107" = 10
"40109" = 9
"40111" = 9
"40113" = 5
"40115" = 10
"40117" = 8
"40119" = 10
"40121" = 9
"40123" = 9
"40125" = 7
"40127" = 9
"40129" = 8
"40131" = 3
"40133" = 10
"40135" = 10
"40137" = 10
"40139" = 6
"40141" = 10
"40143" = 8
"40145" = 3
"40147" = 9
"40149" = 8
"40151" = 8
"40153" = 7
"41001" = 9
"41003" = 9
"41005" = 2
"41007" = 6
"41009" = 4
"41011" = 9
"41013" = 5
"41015" = 8
"41017" = 2
"41019" = 9
"41021" = 4
"41023" = 8
"41025" = 9
"41027" = 4
"41029" = 6
"41031" = 8
"41033" = 9
"41035" = 10
"41037" = 8
"41039" = 7
"41041" = 8
"41043" = 5
"41045" = 10
"41047" = 6
"41049" = 7
"41051" = 5
"41053" = 4
"41055" = 6
"41057" = 8
"41059" = 6
"41061" = 9
"41063" = 6
"41065" = 6
"41067" = 2
"41069" = 9
"41071" = 4
"42001" = 2
"42003" = 4
"42005" = 5
"42007" = 4
"42009" = 5
"42011" = 6
"42013" = 5
"42015" = 6
"42017" = 1
"42019" = 2
"42021" = 6
"42023" = 6
"42025" = 7
"42027" = 8
"42029" = 1
"42031" = 5
"42033" = 7
"42035" = 6
"42037" = 9
"42039" = 8
"42041" = 2
"42043" = 5
"42045" = 4
"42047" = 4
"42049" = 8
"42051" = 8
"42053" = 10
"42055" = 3
"42057" = 5
"42059" = 8
"42061" = 7
"42063" = 6
"42065" = 6
"42067" = 3
"42069" = 6
"42071" = 2
"42073" = 5
"42075" = 2
"42077" = 4
"42079" = 6
"42081" = 4
"42083" = 6
"42085" = 6
"42087" = 8
"42089" = 4
"42091" = 1
"42093" = 3
"42095" = 3
"42097" = 5
"42099" = 2
"42101" = 10
"42103" = 2
"42105" = 9
"42107" = 6
"42109" = 3
"42111" = 6
"42113" = 6
"42115" = 5
"42117" = 6
"42119" = 5
"42121" = 6
"42123" = 5
"42125" = 3
"42127" = 6
"42129" = 4
"42131" = 5
"42133" = 3
"44001" = 2
"44003" = 2
"44005" = 3
"44007" = 7
"44009" = 3
"45001" = 8
"45003" = 8
"45005" = 10
"45007" = 8
"45009" = 10
"45011" = 10
"45013" = 4
"45015" = 4
"45017" = 10
"45019" = 7
"45021" = 10
"45023" = 9
"45025" = 10
"45027" = 10
"45029" = 10
"45031" = 10
"45033" = 10
"45035" = 3
"45037" = 9
"45039" = 10
"45041" = 10
"45043" = 8
"45045" = 4
"45047" = 8
"45049" = 10
"45051" = 6
"45053" = 9
"45055" = 7
"45057" = 5
"45059" = 9
"45061" = 10
"45063" = 4
"45065" = 10
"45067" = 10
"45069" = 10
"45071" = 8
"45073" = 9
"45075" = 10
"45077" = 9
"45079" = 9
"45081" = 9
"45083" = 6
"45085" = 10
"45087" = 10
"45089" = 10
"45091" = 3
"46003" = 3
"46005" = 6
"46007" = 10
"46009" = 7
"46011" = 6
"46013" = 5
"46015" = 6
"46017" = 10
"46019" = 5
"46021" = 4
"46023" = 10
"46025" = 4
"46027" = 9
"46029" = 3
"46031" = 10
"46033" = 3
"46035" = 5
"46037" = 7
"46039" = 3
"46041" = 10
"46043" = 5
"46045" = 4
"46047" = 6
"46049" = 8
"46051" = 3
"46053" = 7
"46055" = 4
"46057" = 2
"46059" = 2
"46061" = 2
"46063" = 5
"46065" = 3
"46067" = 6
"46069" = 4
"46071" = 10
"46073" = 6
"46075" = 6
"46077" = 3
"46079" = 3
"46081" = 6
"46083" = 1
"46085" = 10
"46087" = 3
"46089" = 9
"46091" = 4
"46093" = 3
"46095" = 10
"46097" = 4
"46099" = 3
"46101" = 4
"46102" = 10
"46103" = 5
"46105" = 7
"46107" = 4
"46109" = 9
"46111" = 5
"46115" = 4
"46117" = 2
"46119" = 2
"46121" = 10
"46123" = 10
"46125" = 3
"46127" = 1
"46129" = 9
"46135" = 4
"46137" = 10
"47001" = 7
"47003" = 6
"47005" = 9
"47007" = 10
"47009" = 3
"47011" = 5
"47013" = 10
"47015" = 8
"47017" = 8
"47019" = 9
"47021" = 2
"47023" = 9
"47025" = 9
"47027" = 10
"47029" = 10
"47031" = 8
"47033" = 8
"47035" = 8
"47037" = 8
"47039" = 9
"47041" = 8
"47043" = 5
"47045" = 9
"47047" = 5
"47049" = 10
"47051" = 5
"47053" = 6
"47055" = 5
"47057" = 9
"47059" = 6
"47061" = 10
"47063" = 9
"47065" = 6
"47067" = 10
"47069" = 10
"47071" = 9
"47073" = 9
"47075" = 10
"47077" = 6
"47079" = 9
"47081" = 9
"47083" = 8
"47085" = 5
"47087" = 10
"47089" = 8
"47091" = 10
"47093" = 5
"47095" = 10
"47097" = 10
"47099" = 6
"47101" = 8
"47103" = 8
"47105" = 3
"47107" = 7
"47109" = 8
"47111" = 8
"47113" = 9
"47115" = 9
"47117" = 4
"47119" = 4
"47121" = 8
"47123" = 8
"47125" = 4
"47127" = 3
"47129" = 9
"47131" = 8
"47133" = 8
"47135" = 9
"47137" = 7
"47139" = 6
"47141" = 6
"47143" = 8
"47145" = 6
"47147" = 4
"47149" = 2
"47151" = 10
"47153" = 6
"47155" = 6
"47157" = 9
"47159" = 5
"47161" = 6
"47163" = 9
"47165" = 2
"47167" = 6
"47169" = 9
"47171" = 7
"47173" = 8
"47175" = 9
"47177" = 8
"47179" = 7
"47181" = 10
"47183" = 9
"47185" = 9
"47187" = 1
"47189" = 2
"48001" = 10
"48003" = 5
"48005" = 9
"48007" = 8
"48009" = 3
"48011" = 3
"48013" = 9
"48015" = 4
"48017" = 9
"48019" = 5
"48021" = 5
"48023" = 9
"48025" = 10
"48027" = 7
"48029" = 8
"48031" = 2
"48033" = 3
"48035" = 6
"48037" = 9
"48039" = 2
"48041" = 10
"48043" = 6
"48045" = 8
"48047" = 10
"48049" = 8
"48051" = 7
"48053" = 3
"48055" = 6
"48057" = 8
"48059" = 5
"48061" = 10
"48063" = 9
"48065" = 3
"48067" = 9
"48069" = 9
"48071" = 4
"48073" = 9
"48075" = 10
"48077" = 4
"48079" = 10
"48081" = 8
"48083" = 10
"48085" = 1
"48087" = 9
"48089" = 5
"48091" = 1
"48093" = 9
"48095" = 8
"48097" = 6
"48099" = 6
"48101" = 10
"48103" = 4
"48105" = 8
"48107" = 10
"48109" = 10
"48111" = 4
"48113" = 7
"48115" = 10
"48117" = 9
"48119" = 8
"48121" = 1
"48123" = 9
"48125" = 10
"48127" = 10
"48129" = 9
"48131" = 10
"48133" = 9
"48135" = 9
"48137" = 10
"48139" = 2
"48141" = 10
"48143" = 9
"48145" = 10
"48147" = 7
"48149" = 4
"48151" = 8
"48153" = 9
"48155" = 9
"48157" = 1
"48159" = 8
"48161" = 8
"48163" = 10
"48165" = 7
"48167" = 5
"48169" = 10
"48171" = 2
"48173" = 2
"48175" = 8
"48177" = 9
"48179" = 9
"48181" = 4
"48183" = 9
"48185" = 9
"48187" = 3
"48189" = 10
"48191" = 10
"48193" = 8
"48195" = 5
"48197" = 9
"48199" = 3
"48201" = 9
"48203" = 8
"48205" = 4
"48207" = 10
"48209" = 5
"48211" = 4
"48213" = 8
"48215" = 10
"48217" = 7
"48219" = 9
"48221" = 4
"48223" = 7
"48225" = 10
"48227" = 9
"48229" = 10
"48231" = 7
"48233" = 6
"48235" = 2
"48237" = 9
"48239" = 6
"48241" = 10
"48243" = 10
"48245" = 10
"48247" = 10
"48249" = 10
"48251" = 3
"48253" = 10
"48255" = 10
"48257" = 2
"48259" = 1
"48261" = 7
"48263" = 5
"48265" = 5
"48267" = 8
"48269" = 5
"48271" = 10
"48273" = 10
"48275" = 9
"48277" = 9
"48279" = 10
"48281" = 5
"48283" = 10
"48285" = 5
"48287" = 6
"48289" = 9
"48291" = 8
"48293" = 9
"48295" = 6
"48297" = 9
"48299" = 5
"48301" = 1
"48303" = 9
"48305" = 9
"48307" = 9
"48309" = 8
"48311" = 5
"48313" = 9
"48315" = 10
"48317" = 6
"48319" = 5
"48321" = 10
"48323" = 10
"48325" = 7
"48327" = 10
"48329" = 4
"48331" = 8
"48333" = 6
"48335" = 10
"48337" = 7
"48339" = 4
"48341" = 5
"48343" = 9
"48345" = 9
"48347" = 10
"48349" = 9
"48351" = 10
"48353" = 9
"48355" = 9
"48357" = 5
"48359" = 8
"48361" = 6
"48363" = 8
"48365" = 6
"48367" = 2
"48369" = 8
"48371" = 10
"48373" = 9
"48375" = 10
"48377" = 10
"48379" = 6
"48381" = 3
"48383" = 5
"48385" = 8
"48387" = 10
"48389" = 10
"48391" = 8
"48393" = 1
"48395" = 9
"48397" = 1
"48399" = 8
"48401" = 9
"48403" = 9
"48405" = 10
"48407" = 9
"48409" = 9
"48411" = 9
"48413" = 8
"48415" = 8
"48417" = 5
"48419" = 10
"48421" = 5
"48423" = 6
"48425" = 3
"48427" = 10
"48429" = 9
"48431" = 5
"48433" = 8
"48435" = 7
"48437" = 10
"48439" = 5
"48441" = 9
"48443" = 9
"48445" = 10
"48447" = 8
"48449" = 9
"48451" = 6
"48453" = 4
"48455" = 9
"48457" = 9
"48459" = 8
"48461" = 8
"48463" = 10
"48465" = 10
"48467" = 6
"48469" = 9
"48471" = 10
"48473" = 6
"48475" = 7
"48477" = 7
"48479" = 10
"48481" = 8
"48483" = 7
"48485" = 8
"48487" = 7
"48489" = 10
"48491" = 1
"48493" = 3
"48495" = 8
"48497" = 4
"48499" = 7
"48501" = 6
"48503" = 8
"48505" = 10
"48507" = 10
"49001" = 3
"49003" = 2
"49005" = 4
"49007" = 8
"49009" = 1
"49011" = 1
"49013" = 6
"49015" = 5
"49017" = 3
"49019" = 4
"49021" = 6
"49023" = 2
"49025" = 3
"49027" = 4
"49029" = 1
"49031" = 8
"49033" = 2
"49035" = 2
"49037" = 10
"49039" = 5
"49041" = 3
"49043" = 1
"49045" = 1
"49047" = 5
"49049" = 2
"49051" = 1
"49053" = 3
"49055" = 4
"49057" = 3
"50001" = 2
"50003" = 6
"50005" = 6
"50007" = 3
"50009" = 7
"50011" = 3
"50013" = 2
"50015" = 2
"50017" = 3
"50019" = 6
"50021" = 4
"50023" = 2
"50025" = 4
"50027" = 3
"51001" = 9
"51003" = 1
"51005" = 6
"51007" = 3
"51009" = 5
"51011" = 5
"51013" = 2
"51015" = 2
"51017" = 4
"51019" = 2
"51021" = 7
"51023" = 1
"51025" = 10
"51027" = 10
"51029" = 9
"51031" = 4
"51033" = 4
"51035" = 8
"51036" = 5
"51037" = 9
"51041" = 1
"51043" = 1
"51045" = 5
"51047" = 2
"51049" = 8
"51051" = 10
"51053" = 5
"51057" = 5
"51059" = 1
"51061" = 1
"51063" = 5
"51065" = 2
"51067" = 4
"51069" = 2
"51071" = 5
"51073" = 2
"51075" = 1
"51077" = 9
"51079" = 2
"51081" = 10
"51083" = 9
"51085" = 1
"51087" = 1
"51089" = 9
"51091" = 6
"51093" = 2
"51095" = 1
"51097" = 7
"51099" = 1
"51101" = 1
"51103" = 5
"51105" = 10
"51107" = 1
"51109" = 3
"51111" = 10
"51113" = 3
"51115" = 3
"51117" = 8
"51119" = 6
"51121" = 10
"51125" = 5
"51127" = 1
"51131" = 9
"51133" = 6
"51135" = 10
"51137" = 2
"51139" = 6
"51141" = 7
"51143" = 6
"51145" = 1
"51147" = 10
"51149" = 4
"51153" = 1
"51155" = 6
"51157" = 3
"51159" = 9
"51161" = 2
"51163" = 4
"51165" = 2
"51167" = 9
"51169" = 10
"51171" = 3
"51173" = 9
"51175" = 7
"51177" = 1
"51179" = 1
"51181" = 5
"51183" = 10
"51185" = 10
"51187" = 3
"51191" = 6
"51193" = 8
"51195" = 10
"51197" = 9
"51199" = 1
"51510" = 3
"51520" = 9
"51530" = 8
"51540" = 10
"51550" = 2
"51570" = 3
"51580" = 9
"51590" = 10
"51595" = 10
"51600" = 1
"51610" = 1
"51620" = 10
"51630" = 7
"51640" = 10
"51650" = 5
"51660" = 10
"51670" = 10
"51678" = 10
"51680" = 9
"51683" = 2
"51685" = 1
"51690" = 10
"51700" = 8
"51710" = 9
"51720" = 10
"51730" = 10
"51735" = 1
"51740" = 9
"51750" = 10
"51760" = 10
"51770" = 9
"51775" = 4
"51790" = 5
"51800" = 4
"51810" = 3
"51820" = 5
"51830" = 10
"51840" = 6
"53001" = 9
"53003" = 7
"53005" = 4
"53007" = 4
"53009" = 5
"53011" = 2
"53013" = 6
"53015" = 6
"53017" = 3
"53019" = 9
"53021" = 5
"53023" = 6
"53025" = 5
"53027" = 6
"53029" = 2
"53031" = 4
"53033" = 3
"53035" = 2
"53037" = 7
"53039" = 6
"53041" = 6
"53043" = 4
"53045" = 6
"53047" = 9
"53049" = 6
"53051" = 8
"53053" = 2
"53055" = 4
"53057" = 5
"53059" = 4
"53061" = 1
"53063" = 4
"53065" = 6
"53067" = 3
"53069" = 5
"53071" = 5
"53073" = 6
"53075" = 9
"53077" = 8
"54001" = 10
"54003" = 3
"54005" = 10
"54007" = 10
"54009" = 6
"54011" = 10
"54013" = 10
"54015" = 10
"54017" = 9
"54019" = 10
"54021" = 10
"54023" = 8
"54025" = 10
"54027" = 8
"54029" = 8
"54031" = 9
"54033" = 8
"54035" = 8
"54037" = 3
"54039" = 8
"54041" = 9
"54043" = 10
"54045" = 10
"54047" = 10
"54049" = 8
"54051" = 9
"54053" = 10
"54055" = 9
"54057" = 6
"54059" = 10
"54061" = 9
"54063" = 8
"54065" = 6
"54067" = 10
"54069" = 8
"54071" = 9
"54073" = 7
"54075" = 9
"54077" = 7
"54079" = 4
"54081" = 10
"54083" = 9
"54085" = 10
"54087" = 9
"54089" = 10
"54091" = 9
"54093" = 8
"54095" = 7
"54097" = 10
"54099" = 9
"54101" = 10
"54103" = 9
"54105" = 9
"54107" = 8
"54109" = 10
"55001" = 8
"55003" = 8
"55005" = 3
"55007" = 5
"55009" = 3
"55011" = 2
"55013" = 5
"55015" = 1
"55017" = 3
"55019" = 5
"55021" = 2
"55023" = 5
"55025" = 4
"55027" = 2
"55029" = 2
"55031" = 7
"55033" = 5
"55035" = 6
"55037" = 4
"55039" = 2
"55041" = 6
"55043" = 6
"55045" = 1
"55047" = 6
"55049" = 2
"55051" = 5
"55053" = 6
"55055" = 2
"55057" = 7
"55059" = 4
"55061" = 2
"55063" = 5
"55065" = 3
"55067" = 5
"55069" = 4
"55071" = 4
"55073" = 2
"55075" = 3
"55077" = 5
"55078" = 10
"55079" = 9
"55081" = 5
"55083" = 2
"55085" = 3
"55087" = 1
"55089" = 1
"55091" = 3
"55093" = 2
"55095" = 2
"55097" = 4
"55099" = 5
"55101" = 5
"55103" = 6
"55105" = 4
"55107" = 7
"55109" = 1
"55111" = 3
"55113" = 7
"55115" = 3
"55117" = 2
"55119" = 4
"55121" = 3
"55123" = 8
"55125" = 5
"55127" = 4
"55129" = 5
"55131" = 1
"55133" = 1
"55135" = 3
"55137" = 6
"55139" = 4
"55141" = 4
"56001" = 9
"56003" = 6
"56005" = 2
"56007" = 5
"56009" = 3
"56011" = 2
"56013" = 8
"56015" = 6
"56017" = 6
"56019" = 3
"56021" = 3
"56023" = 2
"56025" = 4
"56027" = 8
"56029" = 5
"56031" = 5
"56033" = 3
"56035" = 1
"56037" = 3
"56039" = 1
"56041" = 3
"56043" = 4
"56045" = 4
OTHER = 0
;
run;

