--[=======[
-------- -------- -------- --------
         TreeAddEx����
-------- -------- -------- --------
]=======]

--[=======[
��
    int       TreeAddEx                 (
                                        table     protofieldsex,
                                        TreeItem  root,
                                        Tvb       tvb,
                                        int       off,
                                        ...
                                        );                                 [-4+, +1, v]
        --����Ҫ���Զ�������Ԫ��
        --protofieldsexΪProtoFieldEx���صĵ�һ����
        --�������� short_abbr[, size|format_function], short_abbr, ... ��ʽ�ṩ
          �����ṩsize��format_functionʱ��ʹ��Ĭ�ϳ���
          ��ָ��fieldδ��Ĭ�ϳ���ʱ��ʹ��ʣ�����������
          ��ָ��size <= 0ʱ������������
          Ĭ�ϳ����б����£�          
            {
            uint8     = 1,
            uint16    = 2,
            uint24    = 3,
            uint32    = 4,
            uint64    = 8,
            int8      = 1,
            int16     = 2,
            int24     = 3,
            int32     = 4,
            int64     = 8,

            framenum  = 4,
            bool      = 1,
            absolute_time = 4,
            relative_time = 4,

            ipv4      = 4,
            ipv6      = 16,
            ether     = 6,
            float     = 4,
            double    = 8,
            };
        --abbr_name�ĵ�һ���ַ�����Ϊ'<'��'>'�����ڱ�ʾfield�Ĵ�С�ˣ�Ĭ�ϴ��
        --abbr_name�����Կո�ָ�ע�͡��ո��Ժ���������ݱ���Ϊ��ע�Ͷ�����֮
        --�������ش���������off
        --���ṩformat_functionʱ��������������ʽ����
          format_function( buf, off, nil, tree_add_func, root, field );
          ��������ڲ�ʹ����tree_add_func��Ӧ����off + size
          ����Ӧ����formatted_string, size��
          ����������Զ�����tree_add_func( root, field, buf( off, size), formatted_string );

        --����ָ��abbr_name��protofieldsex����ƥ�䣬��ʱ�����¹���
          --���ṩformat_functionʱ��������������ʽ����
            format_function( buf, off, nil, tree_add_func, root, field );
            ��������ڲ�ʹ����tree_add_func��Ӧ����off + size
            ����Ӧ����formatted_string, size��
            ����������Զ�����tree_add_func( root, buf( off, size), prefix_string .. formatted_string );
          --��������ڿո��ָ�����ͣ�֧�����Ͳο�FormatEx

        ex:
          off = TreeAddEx( fieldsex, root, tvb, off,
            "xxoo_b",                   --��ʶ���short_abbr���ҿ�ʶ�𳤶�
            "xx", 2,                    --ǿ�Ƴ���
            "xxoo_s", format_xxx        --��ʶ���short_abbr��������ʶ�𳤶ȣ���Ҫ�Զ����ʽ��
            );
          --����Ч���������£�
          xxoo_b        Byte      :0x00
          xx            xx        :0x0000(0)
          xxoo_s        String    :xxxxxxxx

        ex:
          TreeAddEx( fieldsex, root, tvb, off,
            "*xxoo_b uint8",            --ָ����ʶ���֧�����ͣ����ú���ָ����С
            "*xxoo_s string", 6,        --֧�����Ϳ�ʶ�𣬵�ǿ��ָ����С
            "*xxoo_a", 5                --��ָ�����ͣ�Ĭ��bytes
            );
          --����Ч���������£�
          -             *xxoo_b   :0x00(0)
          -             *xxoo_s   :xxxxxx
          -             *xxoo_a   :##########
]=======]

-------- -------- -------- -------- 
local TypeDefaultSize =
  {
  uint8     = 1,
  uint16    = 2,
  uint24    = 3,
  uint32    = 4,
  uint64    = 8,
  int8      = 1,
  int16     = 2,
  int24     = 3,
  int32     = 4,
  int64     = 8,

  framenum  = 4,
  bool      = 1,
  absolute_time = 4,
  relative_time = 4,

  ipv4      = 4,
  ipv6      = 16,
  ether     = 6,
  float     = 4,
  double    = 8,
  };
-------- -------- -------- -------- 
local FieldShort =
  {
  b   = "uint8",
  w   = "uint16",
  d   = "uint32",
  q   = "uint64",
  a   = "bytes",
  s   = "string",

  B   = "uint8",
  W   = "uint16",
  D   = "uint32",
  Q   = "uint64",
  A   = "bytes",
  S   = "string",
  };

local function TreeAddEx_AddOne( arg, k, root, tvb, off, protofieldsex )
  local abbr = arg[ k ];      k = k + 1;

  local func = root.add;
  --�ж���С��
  local isnet = abbr:sub(1, 1);
  if isnet == '<' then
    func = root.add_le;
    abbr = abbr:sub( 2 );
  elseif isnet == '>' then
    abbr = abbr:sub( 2 );
  end

  local abbr, fmttype = abbr:match( "([^ ]+) *([^ ]*)" );

  --�������ͼ�дת��
  if FieldShort[ fmttype ] then
    fmttype = FieldShort[ fmttype ];
  end

  --�մ�����
  if not abbr or abbr == "" then
    return off, k;
  end

  local tb = protofieldsex[abbr];
  local field;
  if tb then
    field = tb.field;
  else
    --��abbr����ʶ��ʱ��fieldΪαǰ׺
    field = string.format( protofieldsex.__fmt, "-", abbr:utf82s() ):s2utf8();
  end

  local kk = arg[ k ];
  local types = type( kk );
  --�����ָ����ʽ����������ʹ��֮
  if types == "function" then
    local ss, size = kk( tvb, off, nil, func, root, field );
    --�����ʽ�������ڲ�������ϣ����ټ���
    if not size or size <= 0 then
      return ss, k + 1;
    end
    --�������Ĭ�����
    if tb then
      func( root, field, tvb( off, size ), ss );
    else
      func( root, tvb( off, size ), field .. ss );
    end
    return off + size, k + 1;
  end

  if tb then
    if types == "number" then
      if kk <= 0 then
        return off, k + 1;
      end
      func( root, tb.field, tvb( off, kk ) );
      return off + kk, k + 1;
    end
    
    --���δ��ָ��������ʹ��Ĭ�ϴ�С
    local size = TypeDefaultSize[ tb.types ];
    if size then
      func( root, field, tvb( off, size ) );
      return off + size, k;
    end

    --���û��ָ����С��Ҳδָ�����ͻ��ʽ����ֱ�����
    if not fmttype or fmttype == "" then
      func( root, field, tvb( off ) );
      return tvb:len(), k;
    end

    --����ʶ��ָ�����ͣ����ָ�����Ͳ���ʶ����ʹ��abbr�����ͻ�bytes
    fmttype = FormatEx[ fmttype ];
    if not fmttype then
      fmttype = FormatEx[ tb.types ] or FormatEx.bytes;
    end
    
    local ss, size = fmttype( tvb, off, nil, func, root, field );
    if not size or size <= 0 then
      return ss, k;
    end
    func( root, field, tvb( off, size), ss );
    return off + size, k;
  end

  --abbr����ʶ��ʱ����������ָ����ʽ���������������ָ�����ͣ������Ϳɸ�ʽ��
  local tps = fmttype;
  if not fmttype or fmttype == "" then
    return error( "abbr:" .. abbr .. " no fixed and no type" );
  end
  if not FormatEx[ fmttype ] then
    return error( "abbr:" .. abbr .. ", type:" .. fmttype .. " no fixed and type unknown" );
  end
  fmttype = FormatEx[ fmttype ];

  --�����ָ����С����ʹ��ָ����С
  if types == "number" then
    local size = kk;
    local ss, size = fmttype( tvb, off, size, func, root, field );
    if not size or size <= 0 then
      return ss, k + 1;
    end
    func( root, tvb( off, size ), field .. ss );
    return off + size, k + 1;
  end
  
  local ss, size = fmttype( tvb, off, nil, func, root, field );
  if not size or size <= 0 then
    return ss, k;
  end
  func( root, tvb( off, size ), field .. ss );
  return off + size, k;
end

function TreeAddEx( protofieldsex, root, tvb, off, ... )
  local off = off or 0;
  local arg = { ... };

  local k = 1;
  while k <= #arg do
    off, k = TreeAddEx_AddOne( arg, k, root, tvb, off, protofieldsex );
    if off >= tvb:len() then
      break;
    end
  end
  return off;
end