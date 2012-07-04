#ifndef INTS_H
#define INTS_H

extern void (*IntHandler1)();
extern void (*IntHandler2)();
extern void (*IntHandler3)();
extern void (*IntHandler4)();
extern void (*IntHandler5)();
extern void (*IntHandler6)();
extern void (*IntHandler7)();

extern void EnableInterrupts();
extern void DisableInterrupts();

#endif
