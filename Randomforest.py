# Python-RandomForest
import pandas as pd
import numpy as np
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
import shap
import os
import xgboost as xgb
from xgboost import plot_importance
import lightgbm as lgb
import numpy as np
import warnings
import eli5
from eli5.sklearn import PermutationImportance
from sklearn.inspection import PartialDependenceDisplay
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from matplotlib.colors import Normalize
from matplotlib.cm import ScalarMappable
import matplotlib.cm as cm
import matplotlib.ticker as mtick
import matplotlib as mpl

mpl.rcParams['svg.fonttype'] = 'none'
mpl.rcParams['svg.hashsalt'] = 'hello'

# import data
df = pd.read_csv(".\data.csv", encoding='utf-8')
df = df[['city', 'city_code', 'zone', 'pro', 'pro1', 'pro_code', 'Eng_name', 'year', 'sum_pop', 'mig', 'mig_m', 'mig_f',
         'mig_0_14', 'mig_15_59', 'mig_60_all',
         'mig_r', 'mig_r_m', 'mig_r_f', 'mig_r_0_14', 'mig_r_15_59', 'mig_r_60_all',  # 6个 因变量-21
         'lnGDP', 'GDP1', 'GDP2', 'GDP3', 'GDP11', 'GDP12', 'GDP13',  # 7个 因变量 28
         # 'Buildings','Roads','Unpaved Roads','Street Furniture','Plant','Sky','Wasteland','Other Nature Space',
         'Buildings', 'Roads', 'Path', 'Street Furniture', 'Vegetation', 'Sky', 'Land', 'Terrain and Waterbody',
         'UPR', 'APC', 'SC1', 'TEM', 'PRE']]
x1 = df.iloc[:, 28:].values
feat_labels1 = df.columns[28:]

x2 = df.iloc[:, 28:36].values
feat_labels2 = df.columns[28:36]

x3 = df.iloc[:, 36:41].values
feat_labels3 = df.columns[36:41]

y1 = df.iloc[:, 15].values
y2 = df.iloc[:, 16].values
y3 = df.iloc[:, 17].values
y4 = df.iloc[:, 18].values
y5 = df.iloc[:, 19].values
y6 = df.iloc[:, 20].values
y7 = df.iloc[:, 21].values
y7 = df.iloc[:, 21].values
y8 = df.iloc[:, 22].values
y9 = df.iloc[:, 23].values
y10 = df.iloc[:, 24].values

x_list = [x2]

y_list = [y1, y2, y3, y4, y5, y7, y6, y8, y9, y10]

# Set max_depth

y_list = [y1, y2, y3, y4, y5, y6, y7, y8, y9, y10]
y_names = ['y1', 'y2', 'y3', 'y4', 'y5', 'y6', 'y7', 'y8', 'y9', 'y10']

param_grid = {
    'n_estimators': [100, 300, 500, 1000],
    'max_depth': [3, 4, 5],
    'min_samples_split': [5, 10, 15],
    'min_samples_leaf': [2, 5, 10]
}

results_df = pd.DataFrame(columns=[
    'Target', 'Best_n_estimators', 'Best_max_depth',
    'Best_min_samples_split', 'Best_min_samples_leaf',
    'Train_R2', 'Test_R2'
])
for i, x in enumerate(x_list):
    for j, y in enumerate(y_list):
        x_train, x_test, y_train, y_test = train_test_split(
            x, y, test_size=0.2, random_state=42
        )

        rf = RandomForestRegressor(random_state=42, n_jobs=-1)

        grid_search = GridSearchCV(
            estimator=rf,
            param_grid=param_grid,
            cv=5,
            scoring='r2',
            n_jobs=-1,
            verbose=0
        )

        grid_search.fit(x_train, y_train)

        best_model = grid_search.best_estimator_
        best_params = grid_search.best_params_

        y_pred_test = best_model.predict(x_test)
        y_pred_train = best_model.predict(x_train)
        test_r2 = r2_score(y_test, y_pred_test)
        train_r2 = r2_score(y_train, y_pred_train)

        results_df.loc[len(results_df)] = [
            y_names[j],
            best_params['n_estimators'],
            best_params['max_depth'],
            best_params['min_samples_split'],
            best_params['min_samples_leaf'],
            # best_params['max_features'],
            train_r2,
            test_r2
        ]
)
results_df.to_csv('best_rf_results.csv', index=False, encoding='utf-8-sig')

# SHAP
best_params_df = pd.read_csv('best_rf_results.csv')
best_params_df.columns = [col.strip() for col in best_params_df.columns]
x2 = df.iloc[:, 28:36].values
feat_labels2 = df.columns[28:36]
x_list = [x2]
feat_labels_list = [feat_labels2]
y_list = [y1, y2, y3, y4, y5, y6, y7, y8, y9, y10]
y_names = ['y1', 'y2', 'y3', 'y4', 'y5', 'y6', 'y7', 'y8', 'y9', 'y10']

for i, x in enumerate(x_list):
    for
j, (y, y_name) in enumerate(zip(y_list, y_names)):
feat_labels = feat_labels_list[i % len(feat_labels_list)]
labels = list(feat_labels)

param_row = best_params_df[best_params_df['y_name'] == y_name]
if param_row.empty:
    best_params = {
'n_estimators': 500,
'max_depth': None,
'min_samples_split': 5,
'min_samples_leaf': 2
}
else:
best_params = {
'n_estimators': int(param_row['best_n_estimators'].values[0]),
'max_depth': None if pd.isna(param_row['best_max_depth'].values[0]) else int(param_row['best_max_depth'].values[0]),
'min_samples_split': int(param_row['best_min_samples_split'].values[0]),
'min_samples_leaf': int(param_row['best_min_samples_leaf'].values[0])
}

x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=0.2, random_state=42)

model = RandomForestRegressor(
n_estimators = best_params['n_estimators'],
max_depth = best_params['max_depth'],
min_samples_split = best_params['min_samples_split'],
min_samples_leaf = best_params['min_samples_leaf'],
max_features = 'sqrt',
random_state = 42,
n_jobs = -1
)
model.fit(x_train, y_train)
y_pred = model.predict(x_test)

mse = mean_squared_error(y_test, y_pred)
mae = mean_absolute_error(y_test, y_pred)
rmse = np.sqrt(mse)
r2 = r2_score(y_test, y_pred)

explainer = shap.TreeExplainer(model)
shap_values = explainer(x_test)
shap_values.feature_names = labels

fig, ax1 = plt.subplots(figsize=(8, 5))

shap.plots.beeswarm(
shap_values,
show = False,
max_display = len(labels),
plot_size = None,
color = plt.get_cmap("viridis_r")
)
ax1 = plt.gca()

beeswarm_labels = [t.get_text() for t in ax1.get_yticklabels()]
beeswarm_order = [labels.index(lab) for lab in beeswarm_labels]

ax2 = ax1.twiny()

mean_abs_shap = np.abs(shap_values.values).mean(axis=0)
mean_abs_shap_ordered = mean_abs_shap[beeswarm_order]

mean_abs_shap_pct = (mean_abs_shap_ordered / mean_abs_shap_ordered.sum()) * 100

bars = ax2.barh(
range(len(mean_abs_shap_pct)),
mean_abs_shap_pct,
color = '#DCE8E4',
height = 0.8,
alpha = 0.6
)

ax2.set_xlim(0, mean_abs_shap_pct.max() * 1.15)
ax2.set_xlabel('Feature contribution (%)', fontsize=16, fontfamily='Calibri')

x_max = int(np.ceil(mean_abs_shap_pct.max()))
ax2.set_xticks(range(0, x_max + 10, 10))
ax2.set_xticklabels([f"{int(tick)}" for tick in ax2.get_xticks()])
ax2.tick_params(axis='x', labelsize=14)

ax1.set_xlabel('SHAP Value', fontsize=16, fontfamily='Calibri')
ax1.tick_params(axis='x', labelsize=14)
ax1.tick_params(axis='y', labelsize=14, width=1.2)

ax2.set_yticks(range(len(beeswarm_labels)))
ax2.set_yticklabels(beeswarm_labels)
ax2.tick_params(axis='y', length=0)

for spine in ['top', 'right', 'bottom', 'left']:
    ax1.spines[spine].set_linewidth(1.2)
ax2.spines[spine].set_linewidth(1.2)

plt.tight_layout()
filename = f'shap_combined_x{i + 1}_y{j + 1}.svg'

plt.savefig(filename, format='svg', bbox_inches='tight', dpi=300)
plt.show()
