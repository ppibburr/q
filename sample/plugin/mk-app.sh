echo -e "\e[34mcompile app\e[0m"
echo -e "\e[35m../../bin/valaq ./app.q --pkg gmodule-2.0\e[0m"
../../bin/valaq ./app.q --pkg gmodule-2.0

echo -e "\e[34mcompile plugin\e[0m"
echo -e "\e[35m../../bin/valaq ./plugin.q --pkg gmodule-2.0 --plugin\e[0m"
../../bin/valaq ./plugin.q --pkg gmodule-2.0 --plugin plugin

echo -e "\e[34mrun app\n\e[35m./app\e[0m\e[1m"
./app

echo -e "\n\n\e[0m"
echo -e "\e[34mClean: \n\e[35mrm -rf app *.so *.vapi q_generated\e[0m"
rm -rf app *.so *.vapi q_generated
