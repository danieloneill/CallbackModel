#include "callbackmodel_plugin.h"
#include "callbackmodel.h"

#include <qqml.h>

void CallbackModelPlugin::registerTypes(const char *uri)
{
    // @uri com.foxmoxie.CallbackModel
    qmlRegisterType<CallbackModel>(uri, 1, 0, "CallbackModel");
}


