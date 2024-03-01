	*Creating a panel dataset containing the production of all countries, 
	*the dataset is created using the raw data downloaded in csv format from the
	*link: https://clio-infra.eu/#
	clear all
	*global path "directory" // replace your directory here 
	global path "C:/Users/shadi/Documents/GitHub/Commodity-Production-Data-Stacked-Area-Graphs" 
	*in the data folder in the directory initially all files should be saved in csv
	*format and default names from the website when downloading. I use the names
	*to rename a variable after the product name. Each file as .xlsx has 3 pages.
	*when saving only the page "Data Long Format" must be saved as csv.
	cd "$path/data"
	clear
	*the loop below opens the files saved as csv and renames the variable "value"
	*based on the file name in the directory. Files are named after the products.
	*later this is used in the panel format. Each file is then saved as a dta file.
	local myfilelist : dir . files"*.csv"
	foreach file of local myfilelist {
	drop _all
	insheet using `file'
	local outfile = subinstr("`file'",".csv","",.)
	*rename value value`outfile'
	gen product = "`outfile'"
	save "`outfile'", replace
	}
	clear
	*note that after running the code the dta files are added to the data file
	*while it had initially only contained the downloaded csv files.
	*however, on this repository one sees the dta fomatted files from the start, 
	*becasue I have cloned the repository after running my code. 
	append using `: dir . files "*.dta"'
	save "$path/_all.dta", replace
********************************************************************************
	*Creating an area stacked graph of copper production among countries:
	***necessary packesge:
	*ssc install colorpalette 
	*If you are using Stata 17 there should be no problem to install colorpalette
	*and you can simply run the command in line 33 by erasing the *.
	*but in version 18 I faced a problem when installing the package using ssc.
	*instead one must search manually for "colorpalette", afterwards click on the
	*hyperlinked name of the package and install manually following the steps.
	*for more info refer to:
	* http://repec.sowi.unibe.ch/stata/palettes/
	*or https://repec.sowi.unibe.ch/stata/palettes/help-colorpalette.html
	ssc install palettes, replace
	ssc install colrspace

	clear 
	*global path ""
	cd "$path" // replace your directory here 
	use "$path/data/copperproduction_compact.dta", clear 
	*Customizing the date range
	drop if year < 1950
	*finding countries with zero product in all years:
	rename country c
	sort c y value
	bysort c: egen sum = sum(value)
	drop if sum == 0
	drop sum
	sort y c product
	*cvalue : cumulative sum 
	by y: gen cvalue = value[1] 
	by y: replace cvalue = value + cvalue[_n-1] if _n>1
	
	*reshaping data for graph
	encode c, gen(cc)
	drop ccode
	reshape wide value c cvalue, i(y) j(cc)

	*labeling country (all 63 countries contained in the dataset) 
	local item = 63
	forvalues i = 1/`item' {
		local label = c`i'[`=_N']
		label variable value`i' "`label'"
		label variable cvalue`i' "`label'"
	}

	local item = 30 //setting colors to the first 30 countries 
	colorpalette HTML , n(`item') nograph
	local toshow
	forval j = `item'(-1)1 {
		local toshow `toshow' (area cvalue`j' y, fcolor("`r(p`j')'") lcolor(black) lwidth(thin))
	}

	#delimit;
	twoway `toshow', xla(1950(10)2012, labsize(tiny)) xtitle("year", size(vsmall)) yla(,labsize(tiny))
	legend(size(tiny) region(color(white)) rowgap(*0.0001) bmargin(tiny) symy(*0.5) symx(*0.5) col(6) pos(6)) ytitle("Copper, Mine production(thousand metric tons)-Worldwide ", size(vsmall)) note("Data Source: British Geological Survey (BGS) U.S. Bureau of Mines, U.S. Geological Survey (USGS)", size(tiny))name(G0, replace)
	;
	#delimit cr
	graph export "$path/graphs/Copper_30.png", as(png) name("G0") replace
	
	local item = 63 //setting colors to all 63 countries 
	colorpalette HTML , n(`item') nograph
	local toshow
	forval j = `item'(-1)1 {
		local toshow `toshow' (area cvalue`j' y, fcolor("`r(p`j')'") lcolor(black) lwidth(thin))
	}
	
	#delimit;
	twoway `toshow', xla(1950(10)2012, labsize(tiny)) xtitle("year", size(vsmall)) yla(,labsize(tiny))
	legend(size(tiny) region(color(white)) rowgap(*0.0001) bmargin(tiny) symy(*0.5) symx(*0.5) col(6) pos(6)) ytitle("Copper, Mine production(thousand metric tons)-Worldwide ", size(vsmall)) note("Data Source: British Geological Survey (BGS) U.S. Bureau of Mines, U.S. Geological Survey (USGS)", size(tiny))name(G0, replace)
	;
	#delimit cr
	graph export "$path/graphs/Copper_all.png", as(png) name("G0") replace
