includes structs;

module LogFirstM
{
  provides
  {
    interface StdControl;
    interface ILogFirst;
  }
  uses
  {
  	interface ObjLog;
  }
}
implementation
{
#include "fluxconst.h"

LogFirst_in *node_in;
LogFirst_out *node_out;
int appendcount;

  command result_t StdControl.init ()
  {
    return SUCCESS;
  }

  command result_t StdControl.start ()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop ()
  {
    return SUCCESS;
  }

  task void doAppend()
  {
  	result_t res;
	static int retries = 0;
	
	res = call ObjLog.append(1, node_in->chunkarr.chunks[appendcount].data, node_in->chunkarr.chunks[appendcount].length);
	
	if (res == FAIL)
	{
		retries++;
		if (retries > 5)
		{
			signal ILogFirst.nodeDone(node_in, node_out, ERR_USR);
		} else {
			post doAppend();
		}
	} else {
		retries = 0;
	}
  }
  
  command result_t ILogFirst.nodeCall (LogFirst_in * in, LogFirst_out * out)
  {
//PUT NODE IMPLEMENTATION HERE
	node_in = in;
	node_out = out;
	appendcount = 0;

	post doAppend();	



//Done signal can be moved if node makes split phase calls.
    return SUCCESS;
  }
  
  event result_t ObjLog.appendDone(int logid, result_t success)
  {
  	if (success == FAIL)
	{
		signal ILogFirst.nodeDone(node_in, node_out, ERR_USR);
		return SUCCESS;
	}
	appendcount++;
	if (appendcount < node_in->chunkarr.num)
	{
		post doAppend();
	} else {
		call ObjLog.tryCommit();
		signal ILogFirst.nodeDone(node_in, node_out, ERR_OK);
	}
  	return SUCCESS;
  }
  
  event result_t ObjLog.readDone(int logid, uint8_t *buffer, uint16_t numbytes, result_t success)
  {
  	return SUCCESS;
  }
  

}
