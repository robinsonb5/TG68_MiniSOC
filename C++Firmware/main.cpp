#include <new>
#include <string.h>

#include "rs232serial.h"



class StaticClass
{
	public:
	StaticClass()
	{
		mystaticmember=42;
	}
	int Get()
	{
		RS232.PutS("In StaticClass::Get()\n\r");
		return(mystaticmember);
	}
	protected:
	static int mystaticmember;
};

int StaticClass::mystaticmember;


class TestClass
{
	public:
	TestClass(int p=4) : t(p)
	{
		RS232.PutS("In TestClass constructor\n\r");
	}
	virtual ~TestClass()
	{
		RS232.PutS("In TestClass Destructor\n\r");
	}
	virtual void Func()
	{
		t*=2;
//		if(t==6)
//			throw "Arbitrary value detected!";
	}
	virtual int Get()
	{
		return(t);
	}
	protected:
	int t;
};


class TC2 : public TestClass
{
	public:
	TC2(int p=6) : TestClass(p*2)
	{
	}
	virtual ~TC2()
	{
	}
	virtual void Func()
	{
		t*=4;
		RS232.PutS("In TC2 function...\n\r");
	}
};

StaticClass staticobject;


int main(int argc,char**argv)
{
	RS232.PutS("Hello world!\n\r");
	RS232.PutS("Doing class tests...\n\r");
//	try
//	{
		char buf[sizeof(TC2)];
		TestClass tc1(*(volatile short *)(0x810000));
		RS232.PutS("Testing placement new...\n\r");
		TC2 *tc2=(TC2 *)buf;
		new (tc2) TC2(tc1.Get());
		tc2->Func();
		*(volatile short *)(0x810006)=tc2->Get();
		TestClass *tc3;
		RS232.PutS("Testing regular new...\n\r");
		tc3=new TestClass(staticobject.Get());
		RS232.PutS("Deleting object...\n\r");
		delete tc3;
//	}
//	catch(const char *err)
//	{
//		*(volatile short*)(0x810006)=0xffff;
//	}
	RS232.PutS("Done...\n\r");
	int c=0;
	while(1)
	{
		HW_PER(PER_HEX)=++c;
	}
	return(0);
}


extern "C"
{
//	_reent *_impure_ptr;
	void c_entry()
	{
		main(0,0);
	}

	void abort()
	{
		// Kill the program here.
		while(1);
	}
	int write(int, void *, size_t s)
	{
		return(s);
	}
	int fwrite(void *,size_t s,size_t t,void *)
	{
		return(s*t);
	}
	int fputs(const char *c,void *)
	{
		return(strlen(c));
	}
	int fputc(char c,void *)
	{
		return(c);
	}
}
