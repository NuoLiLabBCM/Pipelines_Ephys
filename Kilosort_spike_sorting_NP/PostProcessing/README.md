# PostProcessing guide
## Installing Phy 2.0
Go to [Phy](https://github.com/cortex-lab/phy) github and follow instruction there.

For event view (PSTH)
1. Download [event_view_v2.py](https://drive.google.com/file/d/1jYQ9hkdbXR8WYVOlP2Ft0zm_a6MTDaAU)
2. Comment out `# matplotlib.use('TkAgg')` in event_view_v2.py
3. Put my attached event_view_v2.py in the folder `~\.phy\plugins ("~" represents your home directory, e.g., c:\Users\admin\)`
4. Activate the plugin by adding the following line to the config file `~\.phy\phy_config.py:` `c.TemplateGUI.plugins = ['EventPlugin']`



## Sorting in Phy
1) Sort unlabeled units in the data folder, filter   group!='good'
2) Go through and mark 'good' and 'mua' units, based on ISI, feature separation, and waveform (will return next to work on 'mua') (this is step 1 in the instruction) (only mark 'good' or 'mua', leave the rest of the units, will set them to noise at the end)

	ctlr+alt+g --good

	ctlr+alt+m --mua

	ctlr+alt+n --noise
3) i. Filter group=='mua', now work on individual mua by cutting clusters. 

    ii. Cut in feature view, can cltr + stroll to zoom in or out.

	iii. Cltr+mouse click to draw polygon points, after drawing polygon, press 'k' to split cluster.

	iv. Refresh the filter list by pressing enter in the filter field, this will bring up the cut clusters
	label the one you want to save as 'good', or 'noise' if not good enough. label the leftovers as 'noise'
4) Repeat the steps in 3) to finish all mua's. The goal is to have all mua labeled as either 'good' or 'noise'
5) Filter group!='good', now set all the clusters in the list to 'noise'
	(hold 'shift' and select the top and bottom cluster to select all)
6) Now all the units have either label 'good' or 'noise'
7) Save the files.

## PostProcessSpikeData.m
1) Run `PostProcessSpikeData.m`
2) This will extract all units into folder */imecXXX_ks2_SingleUnits/*
3) There are 3types of units

   i. **SingleUnit_imec0_QCXXX** --> units from QC thresholding, no need to check dupicates, go directly to `manual_FinalPlot_CheckBadUnits_kilosort.m`
	
   ii. **SingleUnit_imec0_GoodXXX**	--> units from classification directly as 'good' units, no need to check dupicates, go directly to `manual_FinalPlot_CheckBadUnits_kilosort.m`

   iii. **SingleUnit_imec0_CurationXXX** --> units from manual spike curation in Phy, run steps below.

## manual_CheckForDuplicateClusters_kilosort.m
1) Only run the top portion of this script, up to `%% manually put in the duplicate...`
2) This will generate a bunch of plots in a *\CheckDuplicate* folder within the same SingleUnit folder
3) Look through all plots, each plot shows 1 unit pair, named `SingleUnitFolderName_Unit#`
4) Identify unit pairs that are duplicates, put the pairs into the combine_pairs variable in the script 
	(the bottom portion of the script)
	```matlabb
    If you want to combine more than 2 units, make sure to put the unit in common in the first entry.
		e.g. if combining unit 15 and 32, and also combining unit 32 and 64, then enter
		'32' '15';...
		'32' '64';...
    ```
5) Run the bottom portion of the script to combine the specified unit pair.

## manual_FinalPlot_CheckBadUnits_kilosort.m
1) This will generate a bunch of plots in a *\CheckBadUnits* folder within the same SingleUnit folder.
2) Look through the PNG this files generates, manually move units that don't seem stable to *BadUnit* folder.