xtset city_code year
gen z_mig_r_1 = mig_r *10
gen z_mig_r_0_14_1 = mig_r_0_14 *10
gen z_mig_r_15_59_1 = mig_r_15_59*10
gen z_mig_r_60_all_1 =mig_r_60_all *10
gen z_mig_r_f_1 =mig_r_f *10
gen z_mig_r_m_1 =mig_r_m *10
gen z_gdp1_1 =gdp1 *1
gen z_gdp2_1 =gdp2 *1
gen z_gdp3_1 =gdp3 *1
gen z_ln_gdp = ln(gdp)

local std_vars "building road other_road furniture plant sky earth other_green green grey upr apc sc1 tem pre"
foreach var of local std_vars {
    quietly sum `var'
    gen z_`var' = (`var' - r(mean)) / r(sd)
}
gen type_hdi_city_num = .
replace type_hdi_city_num = 1 if type_hdi_city=="low"
replace type_hdi_city_num = 2 if type_hdi_city=="lower_middle"
replace type_hdi_city_num = 3 if type_hdi_city=="upper_middle"
replace type_hdi_city_num = 4 if type_hdi_city=="high"
replace type_hdi_city_num = 5 if type_hdi_city=="very_high"

**# hausman test
local depvars "z_mig_r_1 z_mig_r_f_1 z_mig_r_m_1 z_mig_r_0_14_1 z_mig_r_15_59_1 z_mig_r_60_all_1 z_gdp1_1 z_gdp2_1 z_gdp3_1 z_ln_gdp"
local indepvars "z_building z_road z_other_road z_furniture z_plant z_sky z_earth z_other_green z_green z_grey"
local controls "z_upr z_apc z_sc1 z_tem z_pre"

foreach dep in `depvars' {
    foreach x in `indepvars' {
        di "===== Dependent: `dep', Independent: `x' ====="
        quietly xtreg `dep' `x' `controls', re
        xttest0
        di ""
    }
}

local depvars "z_mig_r_1 z_mig_r_f_1 z_mig_r_m_1 z_mig_r_0_14_1 z_mig_r_15_59_1 z_mig_r_60_all_1 z_gdp1_1 z_gdp2_1 z_gdp3_1"
local indepvars "z_building z_road z_other_road z_furniture z_plant z_sky z_earth z_other_green z_green z_grey"
local controls "z_upr z_apc z_sc1 z_tem z_pre"

tempname haus
tempfile haus_results
postfile `haus' str20 depvar str20 indepvar haus_p using `haus_results', replace

foreach dep in `depvars' {
    foreach x in `indepvars' {
        di "===== Dependent: `dep', Independent: `x' ====="
        qui xtreg `dep' `x' `controls', fe
        est store fe
        qui xtreg `dep' `x' `controls', re
        est store re
        hausman fe re, sigmamore
        local p = r(p)
        post `haus' ("`dep'") ("`x'") (`p')
        est drop fe re
    }
}
postclose `haus'

**# regression
local depvars "z_mig_r_1 z_mig_r_m_1 z_mig_r_f_1 z_mig_r_0_14_1 z_mig_r_15_59_1 z_mig_r_60_all_1 z_gdp1_1 z_gdp2_1 z_gdp3_1 z_ln_gdp"
local model_types "fe fe fe fe fe fe fe fe fe reg"
local corevars "z_grey z_building z_road z_other_road z_furniture z_green z_plant z_sky z_earth z_other_green"
local controls "z_upr z_apc z_sc1 z_tem z_pre"
xtset city_code year

cap program drop colname
program define colname, rclass
    args n
    local name ""
    while `n' > 0 {
        local r = mod(`n'-1, 26)
        local name = char(65 + `r') + "`name'"
        local n = int((`n'-1)/26)
    }
    return local col `name'
end

local n_models : word count `model_types'
local n_deps : word count `depvars'

cap program drop colname
program define colname, rclass
    args n
    local name ""
    while `n' > 0 {
        local r = mod(`n'-1, 26)
        local name = char(65 + `r') + "`name'"
        local n = int((`n'-1)/26)
    }
    return local col `name'
end

putexcel set standardized_results.xlsx, replace
putexcel A1 = "Core Variable"

local col = 2
foreach y of local depvars {
    colname `col'
    putexcel `r(col)'1 = "`y'"
    local ++col
    colname `col'
    putexcel `r(col)'1 = "stars"
    local ++col
    colname `col'
    putexcel `r(col)'1 = "p-value"
    local ++col
    colname `col'
    putexcel `r(col)'1 = "CI_low"
    local ++col
    colname `col'
    putexcel `r(col)'1 = "CI_high"
    local ++col
}
local row = 2

foreach x of local corevars {
    putexcel A`row' = "`x'"
    local col = 2
    local i = 1

    foreach y of local depvars {
        local model : word `i' of `model_types'

        quietly {
            if "`model'" == "fe" {
                xtreg `y' `x' `controls', fe vce(cluster city_code)
            }
            else if "`model'" == "re" {
                xtreg `y' `x' `controls', re vce(cluster city_code)
            }
            else {
                reg `y' `x' `controls', vce(cluster city_code)
            }
        }

        ****************************************************
        * beta + se
        ****************************************************
        local beta = _b[`x']
        local se   = _se[`x']

        ****************************************************
        * p-value
        ****************************************************
        local t = `beta'/`se'
        if missing(e(df_r)) {
            local pvalue = 2*normal(-abs(`t'))
            local crit = 1.96
        }
        else {
            local pvalue = 2*ttail(e(df_r), abs(`t'))
            local crit = invttail(e(df_r), 0.025)
        }

        ****************************************************
        * stars
        ****************************************************
        local star ""
        if `pvalue' < 0.001 local star "***"
        else if `pvalue' < 0.01 local star "**"
        else if `pvalue' < 0.05 local star "*"

        ****************************************************
        * CI
        ****************************************************
        local lci = `beta' - `crit'*`se'
        local uci = `beta' + `crit'*`se'

        colname `col'
        putexcel `r(col)'`row' = (`beta')
        local ++col
        colname `col'
        putexcel `r(col)'`row' = "`star'"
        local ++col
        colname `col'
        putexcel `r(col)'`row' = (`pvalue')
        local ++col
        colname `col'
        putexcel `r(col)'`row' = (`lci')
        local ++col
        colname `col'
        putexcel `r(col)'`row' = (`uci')
        local ++col

        local ++i
    }
    local ++row
}


**# SUEST
bysort city_code: center z_mig_r_1 z_mig_r_0_14_1 z_mig_r_15_59_1 z_mig_r_60_all_1 z_mig_r_f_1 z_mig_r_m_1 z_gdp1_1 z_gdp2_1 z_gdp3_1 z_grey z_building z_road z_other_road z_furniture z_green z_plant z_sky z_earth z_other_green z_upr z_apc z_sc1 z_tem z_pre
local comparisons "1vs5 1vs4 1vs3 1vs2"

local depvars "z_mig_r_1"
local corevars "z_grey z_building z_road z_other_road z_furniture z_green z_plant z_sky z_earth z_other_green"
local controls "c_z_upr c_z_apc c_z_sc1 c_z_tem z_pre"

tempname results
postfile `results' str20 depvar str20 corevar str10 compare pvalue using "suest_all.dta", replace

foreach comp in `comparisons' {
    if "`comp'" == "1vs5" {
        local group_low 1
        local group_high 5
    }
    else if "`comp'" == "1vs4" {
        local group_low 1
        local group_high 4
    }
    else if "`comp'" == "1vs3" {
        local group_low 1
        local group_high 3
    }
    else if "`comp'" == "1vs2" {
        local group_low 1
        local group_high 2
    }
    di as result "===== Comparing group `group_low' vs `group_high' ====="
    foreach dep in `depvars' {
        foreach x in `corevars' {
            di as text "  dep=`dep', x=`x'"
            
            reg c_`dep' c_`x' `controls' if type_hdi_city_num == `group_low'
            est store low_`x'
            
            reg c_`dep' c_`x' `controls' if type_hdi_city_num == `group_high'
            est store high_`x'
            
            * SUEST
            suest low_`x' high_`x', vce(cluster city_code)
            test [low_`x'_mean]c_`x' = [high_`x'_mean]c_`x'
            local pval = r(p)
            
            post `results' ("`dep'") ("`x'") ("`comp'") (`pval')
            
            estimates drop low_`x' high_`x'
        }
    }
}
postclose `results'


local depvars "z_ln_gdp"
local corevars "z_grey z_building z_road z_other_road z_furniture z_green z_plant z_sky z_earth z_other_green"
local controls "z_upr z_apc z_sc1 z_tem z_pre"

local comparisons "1vs5 1vs4 1vs3 1vs2"
tempname results
postfile `results' str20 depvar str20 corevar str10 compare pvalue using "suest_GDP_all.dta", replace

foreach comp in `comparisons' {
    if "`comp'" == "1vs5" {
        local group_low 1
        local group_high 5
    }
    else if "`comp'" == "1vs4" {
        local group_low 1
        local group_high 4
    }
    else if "`comp'" == "1vs3" {
        local group_low 1
        local group_high 3
    }
    else if "`comp'" == "1vs2" {
        local group_low 1
        local group_high 2
    }
    
    di as result "===== Comparing group `group_low' vs `group_high' ====="
    
    foreach dep in `depvars' {
        di as result "  Dependent variable: `dep'"
        
        foreach x in `corevars' {
            di as text "    Testing: `x'"
            
            quietly reg `dep' `x' `controls' if type_hdi_city_num == `group_low'
            est store low_`x'
            
            quietly reg `dep' `x' `controls' if type_hdi_city_num == `group_high'
            est store high_`x'
            
            suest low_`x' high_`x', vce(cluster city_code)
            
            test [low_`x'_mean]`x' = [high_`x'_mean]`x'
            local pval = r(p)
            
            post `results' ("`dep'") ("`x'") ("`comp'") (`pval')
            
            estimates drop low_`x' high_`x'
        }
    }
}

postclose `results'