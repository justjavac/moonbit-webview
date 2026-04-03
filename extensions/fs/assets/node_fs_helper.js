(function() {
  const rootName = __ROOT_NAME_JS__;
  const extensionName = __EXTENSION_NAME_JS__;
  function normalizeOptions(value) {
    return value && typeof value === 'object' && !Array.isArray(value)
      ? value
      : Object.create(null);
  }
  function readPayload(path, options) {
    const normalized =
      typeof options === 'string' ? { encoding: options } : normalizeOptions(options);
    const payload = { path: path };
    if (typeof normalized.encoding === 'string') {
      payload.encoding = normalized.encoding;
    }
    return payload;
  }
  function writePayload(path, content, options) {
    const normalized =
      typeof options === 'string' ? { encoding: options } : normalizeOptions(options);
    const payload = { path: path, content: content };
    if (typeof normalized.encoding === 'string') {
      payload.encoding = normalized.encoding;
    }
    if (typeof normalized.flush === 'boolean') {
      payload.flush = normalized.flush;
    }
    return payload;
  }
  function statPayload(path, options) {
    const normalized = normalizeOptions(options);
    const payload = { path: path };
    if (typeof normalized.throwIfNoEntry === 'boolean') {
      payload.throw_if_no_entry = normalized.throwIfNoEntry;
    }
    return payload;
  }
  function readdirPayload(path, options) {
    const normalized = normalizeOptions(options);
    const payload = { path: path };
    if (typeof normalized.recursive === 'boolean') {
      payload.recursive = normalized.recursive;
    }
    return payload;
  }
  function mkdirPayload(path, options) {
    const normalized = normalizeOptions(options);
    const payload = { path: path };
    if (typeof normalized.recursive === 'boolean') {
      payload.recursive = normalized.recursive;
    }
    return payload;
  }
  function rmPayload(path, options) {
    const normalized = normalizeOptions(options);
    const payload = { path: path };
    if (typeof normalized.recursive === 'boolean') {
      payload.recursive = normalized.recursive;
    }
    if (typeof normalized.force === 'boolean') {
      payload.force = normalized.force;
    }
    return payload;
  }
  function openFilePayload(path, options) {
    if (typeof options === 'string') {
      return { path: path, flags: options };
    }
    const normalized = normalizeOptions(options);
    const payload = { path: path };
    if (typeof normalized.flags === 'string') {
      payload.flags = normalized.flags;
    }
    if (typeof normalized.read === 'boolean') {
      payload.read = normalized.read;
    }
    if (typeof normalized.write === 'boolean') {
      payload.write = normalized.write;
    }
    if (typeof normalized.append === 'boolean') {
      payload.append = normalized.append;
    }
    if (typeof normalized.create === 'boolean') {
      payload.create = normalized.create;
    }
    if (typeof normalized.truncate === 'boolean') {
      payload.truncate = normalized.truncate;
    }
    if (typeof normalized.createNew === 'boolean') {
      payload.create_new = normalized.createNew;
    }
    return payload;
  }
  function copyFilePayload(src, dest, options) {
    const payload = { src: src, dest: dest };
    if (typeof options === 'boolean') {
      payload.overwrite = options;
      return payload;
    }
    const normalized = normalizeOptions(options);
    if (typeof normalized.overwrite === 'boolean') {
      payload.overwrite = normalized.overwrite;
    }
    return payload;
  }
  function truncatePayload(path, options) {
    if (typeof options === 'number') {
      return { path: path, len: options };
    }
    const normalized = normalizeOptions(options);
    const payload = { path: path };
    if (typeof normalized.len === 'number') {
      payload.len = normalized.len;
    }
    return payload;
  }
  function ridPayload(rid, extra) {
    if (typeof rid !== 'number') {
      throw new TypeError('MoonBit fs rid APIs expect a numeric rid');
    }
    const payload = extra ? Object.assign({}, extra) : Object.create(null);
    payload.rid = rid;
    return payload;
  }
  const root = window[rootName];
  if (!root || typeof root !== 'object' || typeof root['@@ensureExtension'] !== 'function') {
    return;
  }
  const current = root[extensionName];
  if (current && current['@@nodeStyleFs'] === true) {
    return;
  }
  const extensionApi = root['@@ensureExtension'](extensionName);
  const api = Object.create(null);
  Object.defineProperty(api, '@@nodeStyleFs', { value: true });
  Object.defineProperty(api, 'name', { value: extensionName, enumerable: true });
  api.invoke = function(apiName, payload) {
    return extensionApi.invoke(apiName, payload);
  };
  api.on = function(eventName, listener) {
    return extensionApi.on(eventName, listener);
  };
  api.readFile = function(path, options) {
    return extensionApi.readFile(readPayload(path, options));
  };
  api.readTextFile = function(path, options) {
    return extensionApi.readTextFile(readPayload(path, options));
  };
  api.writeFile = function(path, content, options) {
    return extensionApi.writeFile(writePayload(path, content, options));
  };
  api.writeTextFile = function(path, content, options) {
    return extensionApi.writeTextFile(writePayload(path, content, options));
  };
  api.appendFile = function(path, content, options) {
    return extensionApi.appendFile(writePayload(path, content, options));
  };
  api.stat = function(path, options) {
    return extensionApi.stat(statPayload(path, options));
  };
  api.readdir = function(path, options) {
    return extensionApi.readdir(readdirPayload(path, options));
  };
  api.mkdir = function(path, options) {
    return extensionApi.mkdir(mkdirPayload(path, options));
  };
  api.unlink = function(path) {
    return extensionApi.unlink({ path: path });
  };
  api.rm = function(path, options) {
    return extensionApi.rm(rmPayload(path, options));
  };
  api.rename = function(oldPath, newPath) {
    return extensionApi.rename({ old_path: oldPath, new_path: newPath });
  };
  api.copyFile = function(src, dest, options) {
    return extensionApi.copyFile(copyFilePayload(src, dest, options));
  };
  api.realpath = function(path) {
    return extensionApi.realpath({ path: path });
  };
  api.truncate = function(path, options) {
    return extensionApi.truncate(truncatePayload(path, options));
  };
  api.size = function(path) {
    return extensionApi.size({ path: path });
  };
  api.open = function(path, mode) {
    return extensionApi.open({ path: path, mode: typeof mode === 'string' ? mode : 'r' });
  };
  api.openFile = function(path, options) {
    return extensionApi.openFile(openFilePayload(path, options));
  };
  api.read = function(rid, size) {
    return extensionApi.read(ridPayload(rid, { size: size }));
  };
  api.write = function(rid, content) {
    return extensionApi.write(ridPayload(rid, { content: content }));
  };
  api.seek = function(rid, offset, whence) {
    return extensionApi.seek(
      ridPayload(rid, {
        offset: offset,
        whence: typeof whence === 'string' ? whence : 'set',
      }),
    );
  };
  api.fstat = function(rid) {
    return extensionApi.fstat(ridPayload(rid));
  };
  api.flush = function(rid) {
    return extensionApi.flush(ridPayload(rid));
  };
  api.close = function(rid) {
    return extensionApi.close(ridPayload(rid));
  };
  api.exists = function(path) {
    return extensionApi.exists({ path: path });
  };
  root[extensionName] = api;
})();
