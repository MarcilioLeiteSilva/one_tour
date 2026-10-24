const fs = require('fs');

const userBase = [
    {
        "id": "pbc_3142635823",
        "listRule": null,
        "viewRule": null,
        "createRule": null,
        "updateRule": null,
        "deleteRule": null,
        "name": "_superusers",
        "type": "auth",
        "fields": [
            {
                "autogeneratePattern": "[a-z0-9]{15}",
                "hidden": false,
                "id": "text3208210256",
                "max": 15,
                "min": 15,
                "name": "id",
                "pattern": "^[a-z0-9]+$",
                "presentable": false,
                "primaryKey": true,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "cost": 0,
                "hidden": true,
                "id": "password901924565",
                "max": 0,
                "min": 8,
                "name": "password",
                "pattern": "",
                "presentable": false,
                "required": true,
                "system": true,
                "type": "password"
            },
            {
                "autogeneratePattern": "[a-zA-Z0-9]{50}",
                "hidden": true,
                "id": "text2504183744",
                "max": 60,
                "min": 30,
                "name": "tokenKey",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "exceptDomains": null,
                "hidden": false,
                "id": "email3885137012",
                "name": "email",
                "onlyDomains": null,
                "presentable": false,
                "required": true,
                "system": true,
                "type": "email"
            },
            {
                "hidden": false,
                "id": "bool1547992806",
                "name": "emailVisibility",
                "presentable": false,
                "required": false,
                "system": true,
                "type": "bool"
            },
            {
                "hidden": false,
                "id": "bool256245529",
                "name": "verified",
                "presentable": false,
                "required": false,
                "system": true,
                "type": "bool"
            },
            {
                "hidden": false,
                "id": "autodate2990389176",
                "name": "created",
                "onCreate": true,
                "onUpdate": false,
                "presentable": false,
                "system": true,
                "type": "autodate"
            },
            {
                "hidden": false,
                "id": "autodate3332085495",
                "name": "updated",
                "onCreate": true,
                "onUpdate": true,
                "presentable": false,
                "system": true,
                "type": "autodate"
            }
        ],
        "indexes": [
            "CREATE UNIQUE INDEX `idx_tokenKey_pbc_3142635823` ON `_superusers` (`tokenKey`)",
            "CREATE UNIQUE INDEX `idx_email_pbc_3142635823` ON `_superusers` (`email`) WHERE `email` != ''"
        ],
        "system": true,
        "authRule": "",
        "manageRule": null
    },
    {
        "id": "_pb_users_auth_",
        "listRule": "id = @request.auth.id",
        "viewRule": "id = @request.auth.id",
        "createRule": "",
        "updateRule": "id = @request.auth.id",
        "deleteRule": "id = @request.auth.id",
        "name": "users",
        "type": "auth",
        "fields": [
            {
                "autogeneratePattern": "[a-z0-9]{15}",
                "hidden": false,
                "id": "text3208210256",
                "max": 15,
                "min": 15,
                "name": "id",
                "pattern": "^[a-z0-9]+$",
                "presentable": false,
                "primaryKey": true,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "cost": 0,
                "hidden": true,
                "id": "password901924565",
                "max": 0,
                "min": 8,
                "name": "password",
                "pattern": "",
                "presentable": false,
                "required": true,
                "system": true,
                "type": "password"
            },
            {
                "autogeneratePattern": "[a-zA-Z0-9]{50}",
                "hidden": true,
                "id": "text2504183744",
                "max": 60,
                "min": 30,
                "name": "tokenKey",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "exceptDomains": null,
                "hidden": false,
                "id": "email3885137012",
                "name": "email",
                "onlyDomains": null,
                "presentable": false,
                "required": true,
                "system": true,
                "type": "email"
            },
            {
                "hidden": false,
                "id": "bool1547992806",
                "name": "emailVisibility",
                "presentable": false,
                "required": false,
                "system": true,
                "type": "bool"
            },
            {
                "hidden": false,
                "id": "bool256245529",
                "name": "verified",
                "presentable": false,
                "required": false,
                "system": true,
                "type": "bool"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text1579384326",
                "max": 255,
                "min": 0,
                "name": "name",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": false,
                "system": false,
                "type": "text"
            },
            {
                "hidden": false,
                "id": "file376926767",
                "maxSelect": 1,
                "maxSize": 0,
                "mimeTypes": [
                    "image/jpeg",
                    "image/png",
                    "image/svg+xml",
                    "image/gif",
                    "image/webp"
                ],
                "name": "avatar",
                "presentable": false,
                "protected": false,
                "required": false,
                "system": false,
                "thumbs": null,
                "type": "file"
            },
            {
                "hidden": false,
                "id": "autodate2990389176",
                "name": "created",
                "onCreate": true,
                "onUpdate": false,
                "presentable": false,
                "system": false,
                "type": "autodate"
            },
            {
                "hidden": false,
                "id": "autodate3332085495",
                "name": "updated",
                "onCreate": true,
                "onUpdate": true,
                "presentable": false,
                "system": false,
                "type": "autodate"
            }
        ],
        "indexes": [
            "CREATE UNIQUE INDEX `idx_tokenKey__pb_users_auth_` ON `users` (`tokenKey`)",
            "CREATE UNIQUE INDEX `idx_email__pb_users_auth_` ON `users` (`email`) WHERE `email` != ''"
        ],
        "system": false,
        "authRule": "",
        "manageRule": null
    },
    {
        "id": "pbc_4275539003",
        "listRule": "@request.auth.id != '' && recordRef = @request.auth.id && collectionRef = @request.auth.collectionId",
        "viewRule": "@request.auth.id != '' && recordRef = @request.auth.id && collectionRef = @request.auth.collectionId",
        "createRule": null,
        "updateRule": null,
        "deleteRule": "@request.auth.id != '' && recordRef = @request.auth.id && collectionRef = @request.auth.collectionId",
        "name": "_authOrigins",
        "type": "base",
        "fields": [
            {
                "autogeneratePattern": "[a-z0-9]{15}",
                "hidden": false,
                "id": "text3208210256",
                "max": 15,
                "min": 15,
                "name": "id",
                "pattern": "^[a-z0-9]+$",
                "presentable": false,
                "primaryKey": true,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text455797646",
                "max": 0,
                "min": 0,
                "name": "collectionRef",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text127846527",
                "max": 0,
                "min": 0,
                "name": "recordRef",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text4228609354",
                "max": 0,
                "min": 0,
                "name": "fingerprint",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "hidden": false,
                "id": "autodate2990389176",
                "name": "created",
                "onCreate": true,
                "onUpdate": false,
                "presentable": false,
                "system": true,
                "type": "autodate"
            },
            {
                "hidden": false,
                "id": "autodate3332085495",
                "name": "updated",
                "onCreate": true,
                "onUpdate": true,
                "presentable": false,
                "system": true,
                "type": "autodate"
            }
        ],
        "indexes": [
            "CREATE UNIQUE INDEX `idx_authOrigins_unique_pairs` ON `_authOrigins` (collectionRef, recordRef, fingerprint)"
        ],
        "system": true
    },
    {
        "id": "pbc_2281828961",
        "listRule": "@request.auth.id != '' && recordRef = @request.auth.id && collectionRef = @request.auth.collectionId",
        "viewRule": "@request.auth.id != '' && recordRef = @request.auth.id && collectionRef = @request.auth.collectionId",
        "createRule": null,
        "updateRule": null,
        "deleteRule": "@request.auth.id != '' && recordRef = @request.auth.id && collectionRef = @request.auth.collectionId",
        "name": "_externalAuths",
        "type": "base",
        "fields": [
            {
                "autogeneratePattern": "[a-z0-9]{15}",
                "hidden": false,
                "id": "text3208210256",
                "max": 15,
                "min": 15,
                "name": "id",
                "pattern": "^[a-z0-9]+$",
                "presentable": false,
                "primaryKey": true,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text455797646",
                "max": 0,
                "min": 0,
                "name": "collectionRef",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text127846527",
                "max": 0,
                "min": 0,
                "name": "recordRef",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text2462348188",
                "max": 0,
                "min": 0,
                "name": "provider",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text1044722854",
                "max": 0,
                "min": 0,
                "name": "providerId",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "hidden": false,
                "id": "autodate2990389176",
                "name": "created",
                "onCreate": true,
                "onUpdate": false,
                "presentable": false,
                "system": true,
                "type": "autodate"
            },
            {
                "hidden": false,
                "id": "autodate3332085495",
                "name": "updated",
                "onCreate": true,
                "onUpdate": true,
                "presentable": false,
                "system": true,
                "type": "autodate"
            }
        ],
        "indexes": [
            "CREATE UNIQUE INDEX `idx_externalAuths_record_provider` ON `_externalAuths` (collectionRef, recordRef, provider)",
            "CREATE UNIQUE INDEX `idx_externalAuths_collection_provider` ON `_externalAuths` (collectionRef, provider, providerId)"
        ],
        "system": true
    },
    {
        "id": "pbc_2279338944",
        "listRule": "@request.auth.id != '' && recordRef = @request.auth.id && collectionRef = @request.auth.collectionId",
        "viewRule": "@request.auth.id != '' && recordRef = @request.auth.id && collectionRef = @request.auth.collectionId",
        "createRule": null,
        "updateRule": null,
        "deleteRule": null,
        "name": "_mfas",
        "type": "base",
        "fields": [
            {
                "autogeneratePattern": "[a-z0-9]{15}",
                "hidden": false,
                "id": "text3208210256",
                "max": 15,
                "min": 15,
                "name": "id",
                "pattern": "^[a-z0-9]+$",
                "presentable": false,
                "primaryKey": true,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text455797646",
                "max": 0,
                "min": 0,
                "name": "collectionRef",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text127846527",
                "max": 0,
                "min": 0,
                "name": "recordRef",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text1582905952",
                "max": 0,
                "min": 0,
                "name": "method",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "hidden": false,
                "id": "autodate2990389176",
                "name": "created",
                "onCreate": true,
                "onUpdate": false,
                "presentable": false,
                "system": true,
                "type": "autodate"
            },
            {
                "hidden": false,
                "id": "autodate3332085495",
                "name": "updated",
                "onCreate": true,
                "onUpdate": true,
                "presentable": false,
                "system": true,
                "type": "autodate"
            }
        ],
        "indexes": [
            "CREATE INDEX `idx_mfas_collectionRef_recordRef` ON `_mfas` (collectionRef,recordRef)"
        ],
        "system": true
    },
    {
        "id": "pbc_1638494021",
        "listRule": "@request.auth.id != '' && recordRef = @request.auth.id && collectionRef = @request.auth.collectionId",
        "viewRule": "@request.auth.id != '' && recordRef = @request.auth.id && collectionRef = @request.auth.collectionId",
        "createRule": null,
        "updateRule": null,
        "deleteRule": null,
        "name": "_otps",
        "type": "base",
        "fields": [
            {
                "autogeneratePattern": "[a-z0-9]{15}",
                "hidden": false,
                "id": "text3208210256",
                "max": 15,
                "min": 15,
                "name": "id",
                "pattern": "^[a-z0-9]+$",
                "presentable": false,
                "primaryKey": true,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text455797646",
                "max": 0,
                "min": 0,
                "name": "collectionRef",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "autogeneratePattern": "",
                "hidden": false,
                "id": "text127846527",
                "max": 0,
                "min": 0,
                "name": "recordRef",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "cost": 8,
                "hidden": true,
                "id": "password901924565",
                "max": 0,
                "min": 0,
                "name": "password",
                "pattern": "",
                "presentable": false,
                "required": true,
                "system": true,
                "type": "password"
            },
            {
                "autogeneratePattern": "",
                "hidden": true,
                "id": "text3866985172",
                "max": 0,
                "min": 0,
                "name": "sentTo",
                "pattern": "",
                "presentable": false,
                "primaryKey": false,
                "required": false,
                "system": true,
                "type": "text"
            },
            {
                "hidden": false,
                "id": "autodate2990389176",
                "name": "created",
                "onCreate": true,
                "onUpdate": false,
                "presentable": false,
                "system": true,
                "type": "autodate"
            },
            {
                "hidden": false,
                "id": "autodate3332085495",
                "name": "updated",
                "onCreate": true,
                "onUpdate": true,
                "presentable": false,
                "system": true,
                "type": "autodate"
            }
        ],
        "indexes": [
            "CREATE INDEX `idx_otps_collectionRef_recordRef` ON `_otps` (collectionRef, recordRef)"
        ],
        "system": true
    }
];

const idField = {
  autogeneratePattern: '[a-z0-9]{15}',
  hidden: false,
  id: 'text3208210256',
  max: 15,
  min: 15,
  name: 'id',
  pattern: '^[a-z0-9]+$',
  presentable: false,
  primaryKey: true,
  required: true,
  system: true,
  type: 'text'
};

const createdField = {
  hidden: false,
  id: 'autodate2990389176',
  name: 'created',
  onCreate: true,
  onUpdate: false,
  presentable: false,
  system: true,
  type: 'autodate'
};

const updatedField = {
  hidden: false,
  id: 'autodate3332085495',
  name: 'updated',
  onCreate: true,
  onUpdate: true,
  presentable: false,
  system: true,
  type: 'autodate'
};

function makeField(id, name, type, opts = {}) {
  const f = {
    hidden: false,
    id: id,
    name: name,
    presentable: opts.presentable || false,
    primaryKey: false,
    required: opts.required || false,
    system: false,
    type: type
  };
  if (type === 'text') {
    f.autogeneratePattern = '';
    f.max = opts.max || 0;
    f.min = opts.min || 0;
    f.pattern = '';
  } else if (type === 'select') {
    f.maxSelect = 1;
    f.values = opts.values || [];
  } else if (type === 'number') {
    f.max = null;
    f.min = null;
    f.onlyInt = opts.onlyInt || false;
  }
  return f;
}

const estados = {
  id: 'pbc_estados0001',
  name: 'estados',
  type: 'base',
  system: false,
  listRule: '',
  viewRule: '',
  createRule: null,
  updateRule: null,
  deleteRule: null,
  fields: [
    idField,
    makeField('text_est_sigla', 'sigla', 'text', { required: true, max: 2, min: 2, presentable: true }),
    makeField('text_est_nome', 'nome', 'text', { required: true, max: 100, presentable: true }),
    makeField('sel_est_status', 'status', 'select', { required: true, values: ['ativo', 'em_breve'] }),
    makeField('num_est_versao', 'versao_pacote', 'number', { onlyInt: true }),
    createdField,
    updatedField
  ],
  indexes: [
    'CREATE UNIQUE INDEX `idx_estados_sigla` ON `estados` (`sigla`)'
  ]
};

const cidades = {
  id: 'pbc_cidades0001',
  name: 'cidades',
  type: 'base',
  system: false,
  listRule: '',
  viewRule: '',
  createRule: null,
  updateRule: null,
  deleteRule: null,
  fields: [
    idField,
    makeField('text_cid_nome', 'nome', 'text', { required: true, max: 150, presentable: true }),
    makeField('text_cid_slug', 'slug', 'text', { required: true, max: 100, presentable: true }),
    makeField('text_cid_uf', 'estado_sigla', 'text', { required: true, max: 2, min: 2 }),
    makeField('text_cid_tag', 'tag', 'text', { max: 100 }),
    makeField('num_cid_lat', 'lat', 'number'),
    makeField('num_cid_lon', 'lon', 'number'),
    makeField('text_cid_pkg', 'package_size', 'text', { max: 50 }),
    makeField('bool_cid_dest', 'destaque', 'bool'),
    makeField('text_cid_desc_pt', 'descricao_pt', 'text', { max: 2000 }),
    makeField('text_cid_desc_en', 'descricao_en', 'text', { max: 2000 }),
    createdField,
    updatedField
  ],
  indexes: [
    'CREATE UNIQUE INDEX `idx_cidades_slug` ON `cidades` (`slug`)'
  ]
};

const atracoes = {
  id: 'pbc_atracoes001',
  name: 'atracoes',
  type: 'base',
  system: false,
  listRule: '',
  viewRule: '',
  createRule: null,
  updateRule: null,
  deleteRule: null,
  fields: [
    idField,
    makeField('text_atr_nome', 'nome', 'text', { required: true, max: 200, presentable: true }),
    makeField('text_atr_slug', 'slug', 'text', { required: true, max: 150 }),
    makeField('text_atr_cidslug', 'cidade_slug', 'text', { required: true, max: 100 }),
    makeField('text_atr_uf', 'uf', 'text', { required: true, max: 2, min: 2 }),
    makeField('sel_atr_cat', 'categoria', 'select', { required: true, values: ['Praias', 'Cultura', 'Gastronomia', 'Ecoturismo', 'Noite'] }),
    makeField('text_atr_horario', 'horario', 'text', { max: 100 }),
    makeField('num_atr_duracao', 'duracao_min', 'number', { onlyInt: true }),
    makeField('bool_atr_grat', 'gratuito', 'bool'),
    makeField('bool_atr_kid', 'kid_friendly', 'bool'),
    makeField('bool_atr_must', 'must_see', 'bool'),
    makeField('num_atr_score', 'score', 'number'),
    makeField('num_atr_lat', 'lat', 'number'),
    makeField('num_atr_lon', 'lon', 'number'),
    makeField('text_atr_desc_pt', 'descricao_pt', 'text', { max: 3000 }),
    {
      hidden: false,
      id: 'file_atr_fotos',
      maxSelect: 10,
      maxSize: 10485760,
      mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
      name: 'fotos',
      presentable: false,
      protected: false,
      required: false,
      system: false,
      thumbs: null,
      type: 'file'
    },
    createdField,
    updatedField
  ],
  indexes: [
    'CREATE UNIQUE INDEX `idx_atracoes_slug` ON `atracoes` (`slug`)'
  ]
};

const campanhasPush = {
  id: 'pbc_push0000001',
  name: 'campanhas_push',
  type: 'base',
  system: false,
  listRule: '',
  viewRule: '',
  createRule: null,
  updateRule: null,
  deleteRule: null,
  fields: [
    idField,
    makeField('text_push_tit', 'titulo', 'text', { required: true, max: 150, presentable: true }),
    makeField('text_push_msg', 'mensagem', 'text', { required: true, max: 500 }),
    makeField('text_push_uf', 'uf_alvo', 'text', { required: true, max: 2, min: 2 }),
    makeField('text_push_top', 'topico', 'text', { required: true, max: 50 }),
    makeField('sel_push_act', 'action_type', 'select', { required: true, values: ['open_attraction', 'open_city', 'open_url', 'open_trip'] }),
    makeField('text_push_val', 'action_value', 'text', { max: 255 }),
    makeField('sel_push_stat', 'status', 'select', { required: true, values: ['rascunho', 'agendado', 'enviado'] }),
    makeField('num_push_sent', 'sent_count', 'number', { onlyInt: true }),
    createdField,
    updatedField
  ],
  indexes: []
};

userBase.push(estados, cidades, atracoes, campanhasPush);
fs.writeFileSync('server/pocketbase/pb_schema_v23_ready.json', JSON.stringify(userBase, null, 2));
console.log('SUCCESS_CREATED_COMBINED_SCHEMA, Total Collections:', userBase.length);
