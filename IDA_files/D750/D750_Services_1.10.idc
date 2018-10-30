
#include <idc.idc>


static try_make_func(start, name, type)
{	
	auto addr;

	if(start == 0) 
		return;

	addr = start & 0xFFffFFfe;
	if( addr != start )
	{
		SetReg(addr, "T", 1);
	}

	if(strlen(name) > 0 ){
		MakeNameEx(addr, name, 0 );
	}
	MakeFunction(addr, BADADDR);
	
	if(strlen(type) > 0 ){
		SetType(addr, type);
	}
}

static make_vtab(loc, name, type)
{
    Message("loc: %x name: %s\n", loc, name);
    MakeUnknown(loc, 0x10, 0 );
	MakeStructEx(loc, 0x10, "vtab_ent");
    MakeNameEx(loc, sprintf("%s_%s_vtab", type, name), 0);
    
    try_make_func(Dword(loc), sprintf("%s_%s_create", type, name), "");
    try_make_func(Dword(loc+4), sprintf("%s_%s_init", type, name), "");
    try_make_func(Dword(loc+8), sprintf("%s_%s_start", type, name), "");
    try_make_func(Dword(loc+0xc), sprintf("%s_%s_4", type, name), "");
}

static print_op(op)
{
    //n, type, offb, offo, flags, dtyp, reg, value, addr, specval,specflag1, specflag2, specflag3, specflag4
    Message(" n: %d type: %d offb: %x offo: %o flags: %x, dtyp: %d reg: %d value: %x addr: %x\n",op.n, op.type, op.offb, op.offo, op.flags, op.dtyp, op.reg, op.value, op.addr);
}

static srv_block(loc)
{
	auto vtab_func, name_ea, name, obj;
	vtab_func = Dword(loc);
	name_ea = Dword(loc + 0xC );
	name = GetString( name_ea, -1, ASCSTR_C );
    
	// Fixup entry
	MakeUnknown(loc, 0x10, 0 );
	MakeStructEx(loc, 0x10, "srv_ent");

    try_make_func(vtab_func, sprintf("get_%s_srv_vtab", name), "");
    vtab_func = vtab_func & 0xFFffFFfe;
    obj = DecodeInstruction(vtab_func);
    
    //Message("ea %x name %s\n", vtab_func, name); 
    if( obj > 0 && obj.itype == 30 && obj.n == 2 )
    {
        //Message("  n %d itype %d\n", obj.n, obj.itype );
        //print_op(obj.Op0);
        //print_op(obj.Op1);
        make_vtab(Dword(obj.Op1.addr), name, "srv");
    }
}

static srv_blocks(start, end)
{
    auto ea;
    
    ea = start;
    while( ea < end)
    {
        srv_block(ea);
        ea = ea + 0x010;
    }
}

static make_strucs()
{
    auto id, mid;
    if( GetStrucIdByName("srv_ent") == -1 )
    {
        id = AddStrucEx(-1,"srv_ent",0);
        id = GetStrucIdByName("srv_ent");
        mid = AddStrucMember(id,"get_vtab_func",	0x0,	0x20500400,	0,	4,	0XFFFFFFFF,	0,	0x000002);
        mid = AddStrucMember(id,"field_4",	0X4,	0x20000400,	-1,	4);
        mid = AddStrucMember(id,"field_8",	0X8,	0x20000400,	-1,	4);
        mid = AddStrucMember(id,"name",	0XC,	0x20500400,	0,	4,	0XFFFFFFFF,	0,	0x000002);
    }
    
    if( GetStrucIdByName("vtab_ent") == -1 )
    {
        id = AddStrucEx(-1,"vtab_ent",0);
        id = GetStrucIdByName("vtab_ent");
        mid = AddStrucMember(id,"create_func",	0x0,	0x20500400,	0,	4,	0XFFFFFFFF,	0,	0x000002);
        mid = AddStrucMember(id,"init_func",	0X4,	0x20500400,	0,	4,	0XFFFFFFFF,	0,	0x000002);
        mid = AddStrucMember(id,"start_func",	0X8,	0x20500400,	0,	4,	0XFFFFFFFF,	0,	0x000002);
        mid = AddStrucMember(id,"ns_4_func",	0XC,	0x20500400,	0,	4,	0XFFFFFFFF,	0,	0x000002);
    }
}


static main() 
{
	make_strucs();
	
    srv_blocks(0x1003DF04, 0x1003E094);
}