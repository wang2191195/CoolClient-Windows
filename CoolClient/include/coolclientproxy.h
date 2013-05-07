#ifndef COOLCLIENTPROXY
#define COOLCLIENTPROXY

#define COOLCLIENT_PROXY_LUA_CLASS "CoolDown.CoolClient.Proxy.Class"
#define COOLCLIENT_PROXY_LUA_OBJ "CoolDown.CoolClient.Proxy"

#include "client.h"
#include <Windows.h>
#include <XLLuaRuntime.h>

using CoolDown::Client::CoolClient;
using CoolDown::Client::ClientThread;

class CoolClientProxy{
public:
	//CoolClientProxy();
	//called by lua files
	static int RunClientAsync(lua_State* luaState);
	static int TestTable(lua_State* luaState);
	static int SearchResource(lua_State* luaState);

public:
	//work with lua runtime
	static CoolClientProxy* __stdcall Instance(void*);
	static void RegisterObj(XL_LRT_ENV_HANDLE hEnv);

private:
	static CoolClient* pCoolClient;
};

#endif